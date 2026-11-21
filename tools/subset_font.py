"""언어별 글꼴을 게임에 쓰는 글자만 남겨서 작게 만들기 (웹 로딩용)
사용: python3 tools/subset_font.py <원본 글꼴.ttf> <언어 ja|zh_CN|zh_TW> 
결과: assets/fonts/<언어>.ttf
"""
import re, sys, subprocess
src, lang = sys.argv[1], sys.argv[2]
txt = open(f"i18n/{lang}.gd", encoding="utf-8").read()
chars = set(re.sub(r'\\[n"\\]', '', txt))
chars |= set(chr(c) for c in range(0x20, 0x7F))          # 영문·숫자·기호
chars |= set("ー〜・「」『』（）！？、。…♥★☆→←↑↓×＋－：；％0123456789")
open("/tmp/_chars.txt", "w", encoding="utf-8").write("".join(sorted(chars)))
subprocess.run(["pyftsubset", src, "--text-file=/tmp/_chars.txt", f"--output-file=assets/fonts/{lang}.ttf",
                "--layout-features=*", "--no-hinting"], check=True)
print("ok:", len(chars), "chars ->", f"assets/fonts/{lang}.ttf")
