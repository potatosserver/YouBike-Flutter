import os
import json
import re

def audit_arb_files(arb_dir):
    print("\n--- [1] 翻譯對齊檢查 (ARB Alignment) ---")
    zh_path = os.path.join(arb_dir, 'app_zh.arb')
    en_path = os.path.join(arb_dir, 'app_en.arb')
    
    if not os.path.exists(zh_path) or not os.path.exists(en_path):
        print("❌ 找不到 ARB 檔案，請檢查路徑。")
        return

    with open(zh_path, 'r', encoding='utf-8') as f:
        zh_data = json.load(f)
    with open(en_path, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    # 只提取 Key (排除 @ 開頭的描述項)
    zh_keys = {k for k in zh_data.keys() if not k.startswith('@')}
    en_keys = {k for k in en_data.keys() if not k.startswith('@')}

    missing_in_en = zh_keys - en_keys
    missing_in_zh = en_keys - zh_keys

    if not missing_in_en and not missing_in_zh:
        print("✅ 所有 Key 在中英文之間完全對齊。")
    else:
        if missing_in_en:
            print(f"❌ 英文版 (app_en.arb) 缺失 {len(missing_in_en)} 個 Key:")
            for k in sorted(missing_in_en): print(f"  - {k}")
        if missing_in_zh:
            print(f"❌ 中文版 (app_zh.arb) 缺失 {len(missing_in_zh)} 個 Key:")
            for k in sorted(missing_in_zh): print(f"  - {k}")

def scan_hardcoded_strings(lib_dir):
    print("\n--- [2] 硬編碼文字掃描 (Hard-coded Strings) ---")
    
    # 匹配 Text("...") 或 Text(l10n.something)
    # 這裡我們主要抓取直接用字串定義的 Text 組件
    text_widget_pattern = re.compile(r'Text\s*\(\s*["\'](.*?)["\']')
    
    # 排除名單：一些必要的硬編碼 (如 ID, API 路徑, 日誌標籤)
    exclude_patterns = [
        r'^\s*$',                       # 空字串
        r'^[\d\s\.,%]+$',               # 純數字/百分比/標點
        r'^[A-Z_]+$',                    # 全大寫常數/Enum
        r'^\w+$',                       # 單個英文單字 (可能是 ID)
        r'http[s]?://',                 # URL
        r'\[LOC-ERROR\]',                # 已知日誌標記
    ]

    hardcoded_found = 0
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    lines = f.readlines()
                    for i, line in enumerate(lines):
                        match = text_widget_pattern.search(line)
                        if match:
                            text = match.group(1)
                            # 檢查是否符合排除條件
                            is_excluded = any(re.match(p, text) for p in exclude_patterns)
                            if not is_excluded:
                                print(f"🚩 {path}:{i+1} -> \"{text}\"")
                                hardcoded_found += 1
    
    if hardcoded_found == 0:
        print("✅ 未發現明顯的硬編碼 UI 文字。")
    else:
        print(f"\n總共發現 {hardcoded_found} 處可能的硬編碼文字。")

def audit_unused_translations(arb_dir, lib_dir):
    print("\n--- [3] 未利用詞條檢查 (Unused Keys) ---")
    zh_path = os.path.join(arb_dir, 'app_zh.arb')
    if not os.path.exists(zh_path):
        print("❌ 找不到 ARB 檔案。")
        return

    with open(zh_path, 'r', encoding='utf-8') as f:
        zh_data = json.load(f)
    
    # 提取所有 Key (排除 @ 開頭)
    all_keys = {k for k in zh_data.keys() if not k.startswith('@')}
    used_keys = set()

    # 掃描所有 dart 檔案
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                path = os.path.join(root, file)
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    for key in all_keys:
                        # 搜尋 .key 形式的引用 (例如 l10n.app_title)
                        if f".{key}" in content:
                            used_keys.add(key)
    
    unused_keys = all_keys - used_keys

    if not unused_keys:
        print("✅ 所有翻譯詞條都已被使用。")
    else:
        print(f"🚩 發現 {len(unused_keys)} 個未被使用的翻譯 Key:")
        for k in sorted(unused_keys):
            print(f"  - {k}")

if __name__ == "__main__":
    import sys
    PROJECT_LIB = sys.argv[1] if len(sys.argv) > 1 else '/home/user/StudioProjects/YouBike-Android/lib'
    ARB_DIR = os.path.join(PROJECT_LIB, 'l10n')
    
    audit_arb_files(ARB_DIR)
    scan_hardcoded_strings(PROJECT_LIB)
    audit_unused_translations(ARB_DIR, PROJECT_LIB)
