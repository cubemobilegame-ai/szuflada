import re, subprocess, sys, time
want = sys.argv[1]
for attempt in range(3):
    subprocess.run(['adb', 'shell', 'uiautomator', 'dump', '/sdcard/ui.xml'], capture_output=True)
    xml = subprocess.run(['adb', 'shell', 'cat', '/sdcard/ui.xml'], capture_output=True, text=True).stdout
    for m in re.finditer(r'<node [^>]*>', xml):
        n = m.group(0)
        txt = ' '.join(re.findall(r'(?:text|content-desc)="([^"]*)"', n))
        if want in txt:
            b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n)
            if b:
                x1, y1, x2, y2 = map(int, b.groups())
                x, y = (x1 + x2) // 2, (y1 + y2) // 2
                subprocess.run(['adb', 'shell', 'input', 'tap', str(x), str(y)])
                print(f'tap "{want}" at {x},{y} bounds {x1},{y1},{x2},{y2}')
                sys.exit(0)
    time.sleep(2)
print(f'NIE ZNALEZIONO "{want}"')
