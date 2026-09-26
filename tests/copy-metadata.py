import json, os, pathlib, select, signal, subprocess, sys, time

assert os.geteuid() != 0, 'run as an ordinary user: root bypasses the injected permission failure'
left, right = map(pathlib.Path, sys.argv[1:3])
for root in (left, right):
    assert root.is_absolute() and root.resolve() == root
    assert not root.is_relative_to(pathlib.Path.home())
    assert (root / '.bachy-test-sandbox').is_file()
assert left.stat().st_dev != right.stat().st_dev, 'cross-filesystem fixture required'
binary = str(pathlib.Path(__file__).resolve().parents[1] / 'target/debug/bachy')
env = dict(os.environ, XDG_DATA_HOME=str(left/'data'), XDG_STATE_HOME=str(left/'state'), XDG_CONFIG_HOME=str(left/'config'), XDG_CACHE_HOME=str(left/'cache'))
process = subprocess.Popen([binary, '--backend'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
buffer = b''

def send(message):
    process.stdin.write((json.dumps(message)+'\n').encode()); process.stdin.flush()

def receive(wanted, hook=None):
    global buffer
    deadline = time.monotonic()+20
    while time.monotonic()<deadline:
        while b'\n' in buffer:
            line, buffer = buffer.split(b'\n',1)
            item = json.loads(line)
            if hook: hook(item)
            if item.get('t') == wanted: return item
        if select.select([process.stdout], [], [], 0.1)[0]:
            chunk = os.read(process.stdout.fileno(), 65536)
            assert chunk, 'backend exited: '+process.stderr.read().decode()
            buffer += chunk
    raise AssertionError('timed out waiting for '+wanted)

def stamp(path, value):
    os.setxattr(path, b'user.bachy.lesson', value)
    os.utime(path, ns=(900_000_000_123_456_789, 950_000_000_987_654_321))
    info=path.stat()
    return info.st_atime_ns, info.st_mtime_ns

def check(path, times, value):
    info=path.stat()
    assert info.st_mtime_ns == times[1], (str(path), info.st_mtime_ns, times)
    if not path.is_dir():
        assert info.st_atime_ns == times[0], (str(path), info.st_atime_ns, times)
    elif info.st_atime_ns != times[0]:
        print('LIMIT directory access time observed after concurrent size scan:', path.name, flush=True)
    assert os.getxattr(path,b'user.bachy.lesson')==value

try:
    for origin, target, op in [(left,right,'copy'),(right,left,'move')]:
        src=origin/('tree-'+op); src.mkdir()
        sub=src/'nested'; sub.mkdir()
        leaf=sub/'file'; leaf.write_bytes(b'original contents')
        child_time=stamp(leaf,b'child\x00\xff')
        sub_time=stamp(sub,b'nested')
        root_time=stamp(src,b'root')
        target_dir=target/('destination-'+op); target_dir.mkdir()
        send({'c':'transfer','op':op,'paths':[str(src)],'dest':str(target_dir)})
        result=receive('transferdone')
        assert result['ok']==1 and result['failed']==0, result
        copied=target_dir/src.name
        check(copied,root_time,b'root'); check(copied/'nested',sub_time,b'nested'); check(copied/'nested/file',child_time,b'child\x00\xff')
        assert src.exists()==(op=='copy')
        print('PASS cross-filesystem',op,'tree modification times and user attributes (file access times exact)',flush=True)

    src=left/'metadata-failure.bin'
    with src.open('wb') as f: f.truncate(512*1024*1024)
    stamp(src,b'must survive')
    src.chmod(0o400)
    dst=right/'failed-move'; dst.mkdir()
    injected=False
    errors=[]
    def fault(item):
        global injected
        if item.get('t')=='transferitem': errors.append(item)
        if not injected and item.get('t')=='transferprogress' and 0<item.get('bytes',0)<512*1024*1024:
            os.kill(process.pid,signal.SIGSTOP)
            os.waitpid(process.pid,os.WUNTRACED)
            try:
                assert src.exists(), 'move completed before fault injection'
                src.chmod(0)
                injected=True
            finally:
                os.kill(process.pid,signal.SIGCONT)
    send({'c':'transfer','op':'move','paths':[str(src)],'dest':str(dst)})
    result=receive('transferdone',fault)
    src.chmod(0o400)
    assert injected and result['failed']==1 and result['ok']==0, result
    assert any('could not preserve metadata' in item.get('err','') for item in errors), errors
    assert src.exists() and (dst/src.name).exists()
    assert (dst/src.name).stat().st_mode & 0o7777 == 0o400
    send({'c':'undo'})
    result=receive('undone')
    assert result['ok'] and src.exists() and not (dst/src.name).exists(), result
    print('PASS failed cross-filesystem move kept source, reported metadata failure, restored mode; undo removed partial',flush=True)
finally:
    if process.poll() is None:
        os.kill(process.pid,signal.SIGCONT)
        send({'c':'quit'})
        try: process.wait(timeout=3)
        except subprocess.TimeoutExpired: process.kill(); process.wait()
