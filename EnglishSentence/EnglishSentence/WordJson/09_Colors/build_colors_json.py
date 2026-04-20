#!/usr/bin/env python3
"""生成 01_Colors.json；依赖同目录 build_color_tokens.tsv"""
import csv
import json
from pathlib import Path

DIR = Path(__file__).resolve().parent

# keyword, keyword_zh, section_key, section_zh, original, translation, tokens
DATA = [
    # 1 基础彩虹色
    ("red", "红色", "basic_rainbow", "基础彩虹色", "The red apple looks sweet", "红苹果看起来很甜", ["The", "red", "apple", "looks", "sweet"]),
    ("orange", "橙色", "basic_rainbow", "基础彩虹色", "I like orange juice", "我喜欢橙汁", ["I", "like", "orange", "juice"]),
    ("yellow", "黄色", "basic_rainbow", "基础彩虹色", "The yellow taxi stopped", "黄色出租车停了下来", ["The", "yellow", "taxi", "stopped"]),
    ("green", "绿色", "basic_rainbow", "基础彩虹色", "Grass is green in spring", "春天草是绿的", ["Grass", "is", "green", "in", "spring"]),
    ("blue", "蓝色", "basic_rainbow", "基础彩虹色", "The blue sky is clear", "蓝天很清澈", ["The", "blue", "sky", "is", "clear"]),
    ("indigo", "靛蓝色", "basic_rainbow", "基础彩虹色", "Indigo dye was precious", "靛蓝染料曾很珍贵", ["Indigo", "dye", "was", "precious"]),
    ("violet", "紫罗兰色", "basic_rainbow", "基础彩虹色", "She wore a violet dress", "她穿了一条紫罗兰色连衣裙", ["She", "wore", "a", "violet", "dress"]),
    ("purple", "紫色", "basic_rainbow", "基础彩虹色", "Purple grapes are ripe", "紫葡萄熟了", ["Purple", "grapes", "are", "ripe"]),
    # 2 中性色与基础色
    ("black", "黑色", "neutrals", "中性色与基础色", "Black coffee has no milk", "黑咖啡不加奶", ["Black", "coffee", "has", "no", "milk"]),
    ("white", "白色", "neutrals", "中性色与基础色", "White snow covers the ground", "白雪覆盖大地", ["White", "snow", "covers", "the", "ground"]),
    ("gray", "灰色", "neutrals", "中性色与基础色", "The gray cat slept", "灰猫在睡觉", ["The", "gray", "cat", "slept"]),
    ("brown", "棕色", "neutrals", "中性色与基础色", "Brown leather feels soft", "棕色皮革摸起来很软", ["Brown", "leather", "feels", "soft"]),
    ("beige", "米色", "neutrals", "中性色与基础色", "The walls are beige", "墙是米色的", ["The", "walls", "are", "beige"]),
    # 3 常见进阶色彩
    ("pink", "粉红色", "variations", "常见进阶色彩", "Pink roses smell sweet", "粉红玫瑰闻起来很香", ["Pink", "roses", "smell", "sweet"]),
    ("cyan", "青色", "variations", "常见进阶色彩", "The cyan screen flickered", "青色屏幕在闪", ["The", "cyan", "screen", "flickered"]),
    ("aqua", "水蓝色", "variations", "常见进阶色彩", "Aqua water looks clear", "水蓝色的水看起来很清", ["Aqua", "water", "looks", "clear"]),
    ("gold", "金色", "variations", "常见进阶色彩", "She won a gold medal", "她赢得了金牌", ["She", "won", "a", "gold", "medal"]),
    ("silver", "银色", "variations", "常见进阶色彩", "He bought a silver ring", "他买了一枚银戒指", ["He", "bought", "a", "silver", "ring"]),
    ("navy blue", "藏青色", "variations", "常见进阶色彩", "He wore a navy blue suit", "他穿了一套藏青色西装", ["He", "wore", "a", "navy", "blue", "suit"]),
    ("turquoise", "蓝绿色", "variations", "常见进阶色彩", "She chose turquoise paint", "她选了青绿色油漆", ["She", "chose", "turquoise", "paint"]),
    ("lavender", "淡紫色", "variations", "常见进阶色彩", "Lavender fields smell beautiful", "薰衣草田闻起来很香", ["Lavender", "fields", "smell", "beautiful"]),
    # 4 修饰词
    ("light", "浅", "modifiers", "亮度与饱和度修饰词", "She wore a light blue dress", "她穿了一条浅蓝色连衣裙", ["She", "wore", "a", "light", "blue", "dress"]),
    ("dark", "深", "modifiers", "亮度与饱和度修饰词", "He likes dark green tea", "他喜欢深绿色的茶", ["He", "likes", "dark", "green", "tea"]),
    ("bright", "鲜艳的", "modifiers", "亮度与饱和度修饰词", "Bright red flowers bloomed", "鲜红的花开了", ["Bright", "red", "flowers", "bloomed"]),
    ("pale", "苍白的；暗淡的", "modifiers", "亮度与饱和度修饰词", "Her lips were pale pink", "她的嘴唇是淡粉色的", ["Her", "lips", "were", "pale", "pink"]),
]

KW_PH = {
    "red": ("/red/", "/red/"),
    "orange": ("/ˈɒrɪndʒ/", "/ˈɔːrɪndʒ/"),
    "yellow": ("/ˈjeləʊ/", "/ˈjeloʊ/"),
    "green": ("/ɡriːn/", "/ɡriːn/"),
    "blue": ("/bluː/", "/bluː/"),
    "indigo": ("/ˈɪndɪɡəʊ/", "/ˈɪndɪɡoʊ/"),
    "violet": ("/ˈvaɪələt/", "/ˈvaɪələt/"),
    "purple": ("/ˈpɜːpl/", "/ˈpɜːrpl/"),
    "black": ("/blæk/", "/blæk/"),
    "white": ("/waɪt/", "/waɪt/"),
    "gray": ("/ɡreɪ/", "/ɡreɪ/"),
    "brown": ("/braʊn/", "/braʊn/"),
    "beige": ("/beɪʒ/", "/beɪʒ/"),
    "pink": ("/pɪŋk/", "/pɪŋk/"),
    "cyan": ("/ˈsaɪən/", "/ˈsaɪən/"),
    "aqua": ("/ˈækwə/", "/ˈækwə/"),
    "gold": ("/ɡəʊld/", "/ɡoʊld/"),
    "silver": ("/ˈsɪlvə(r)/", "/ˈsɪlvər/"),
    "navy blue": ("/ˈneɪvi ˈbluː/", "/ˈneɪvi ˈbluː/"),
    "turquoise": ("/ˈtɜːkwɔɪz/", "/ˈtɜːrkɔɪz/"),
    "lavender": ("/ˈlævəndə(r)/", "/ˈlævəndər/"),
    "light": ("/laɪt/", "/laɪt/"),
    "dark": ("/dɑːk/", "/dɑːrk/"),
    "bright": ("/braɪt/", "/braɪt/"),
    "pale": ("/peɪl/", "/peɪl/"),
}


def ranges_for(s: str, tokens: list[str]) -> list[tuple[str, int, int]]:
    pos = 0
    out = []
    for w in tokens:
        i = s.find(w, pos)
        if i < 0:
            raise ValueError(f"{w!r} not found from {pos} in {s!r}")
        out.append((w, i, i + len(w)))
        pos = i + len(w)
    return out


def pat_code(kw: str) -> str:
    return "COL_" + kw.upper().replace(" ", "_")


def load_meta() -> dict[str, dict]:
    meta = {}
    tsv = DIR / "build_color_tokens.tsv"
    with open(tsv, encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            meta[row["word"]] = row
    return meta


def main():
    meta = load_meta()
    sentences = []
    for idx, (kw, kw_zh, sec, sec_zh, orig, trans, toks) in enumerate(DATA, start=1):
        sid = f"COL_{idx:03d}"
        for w in toks:
            if w not in meta:
                raise SystemExit(f"Missing TSV row for token {w!r} in {orig!r}")
        rs = ranges_for(orig, toks)
        analysis = []
        for w, a, b in rs:
            m = meta[w]
            bf = w.lower() if w != "I" else "I"
            analysis.append(
                {
                    "word": w,
                    "base_form": bf,
                    "range": [a, b],
                    "tag": m["tag"],
                    "type": m["type"],
                    "chinese_definition": m["chinese_definition"],
                    "explanation": m["explanation"],
                    "phonetics": {
                        "uk": m["uk"],
                        "us": m["us"],
                        "audio_uk": "",
                        "audio_us": "",
                    },
                }
            )
        uk, us = KW_PH[kw]
        sentences.append(
            {
                "id": sid,
                "sentence_info": {
                    "original": orig,
                    "translation": trans,
                    "sentence_pattern": f"{sec_zh} · {kw}",
                    "pattern_code": pat_code(kw),
                    "difficulty_level": 1,
                    "tags": ["colors", sec, kw.replace(" ", "_"), "basic_vocabulary"],
                    "keyword": kw,
                    "keyword_translation": kw_zh,
                    "keyword_phonetics": {
                        "uk": uk,
                        "us": us,
                        "audio_uk": "",
                        "audio_us": "",
                    },
                },
                "analysis": analysis,
            }
        )

    out = {
        "unit_name": "颜色词汇 - 彩虹色、中性色、进阶色与修饰词",
        "description": "共 25 个词条：基础彩虹色 8 词、中性色 5 词、常见进阶色 8 词、亮度与饱和度修饰词（light / dark / bright / pale）4 词；附例句与逐词解析。",
        "category": "Colors",
        "code": "COL_01",
        "sentences": sentences,
    }
    out_path = DIR / "01_Colors.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("Wrote", out_path, "sentences:", len(sentences))


if __name__ == "__main__":
    main()
