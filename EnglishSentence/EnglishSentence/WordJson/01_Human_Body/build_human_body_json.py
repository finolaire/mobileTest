#!/usr/bin/env python3
# 生成 01_Human_Body.json；依赖同目录下 build_body_tokens.tsv
import csv
import json
from pathlib import Path

DIR = Path(__file__).resolve().parent

DATA = [
    ("hair", "头发", "head", "头部", "She brushed her hair", "她梳了梳头发", ["She", "brushed", "her", "hair"]),
    ("forehead", "前额", "head", "头部", "He has a wide forehead", "他前额很宽", ["He", "has", "a", "wide", "forehead"]),
    ("eye", "眼睛", "head", "头部", "Close your eyes", "闭上眼睛", ["Close", "your", "eyes"]),
    ("eyebrow", "眉毛", "head", "头部", "She raised an eyebrow", "她扬了扬眉毛", ["She", "raised", "an", "eyebrow"]),
    ("eyelash", "睫毛", "head", "头部", "Her eyelashes are long", "她的睫毛很长", ["Her", "eyelashes", "are", "long"]),
    ("ear", "耳朵", "head", "头部", "Whisper in my ear", "在我耳边低语", ["Whisper", "in", "my", "ear"]),
    ("nose", "鼻子", "head", "头部", "My nose is cold", "我的鼻子很冷", ["My", "nose", "is", "cold"]),
    ("cheek", "脸颊", "head", "头部", "Tears ran down her cheek", "泪水顺着她的脸颊流下", ["Tears", "ran", "down", "her", "cheek"]),
    ("mouth", "嘴巴", "head", "头部", "Open your mouth", "张开嘴", ["Open", "your", "mouth"]),
    ("lip", "嘴唇", "head", "头部", "Her lips are dry", "她的嘴唇很干", ["Her", "lips", "are", "dry"]),
    ("tooth", "牙齿", "head", "头部", "I have a loose tooth", "我有一颗牙松了", ["I", "have", "a", "loose", "tooth"]),
    ("tongue", "舌头", "head", "头部", "You might burn your tongue on hot soup", "热汤可能会烫到舌头", ["You", "might", "burn", "your", "tongue", "on", "hot", "soup"]),
    ("chin", "下巴", "head", "头部", "He rested his chin on his hand", "他用手托着下巴", ["He", "rested", "his", "chin", "on", "his", "hand"]),
    ("neck", "脖子；颈部", "head", "头部", "The scarf covers my neck", "围巾裹着我的脖子", ["The", "scarf", "covers", "my", "neck"]),
    ("shoulder", "肩膀", "torso", "躯干", "He shrugged his shoulders", "他耸了耸肩", ["He", "shrugged", "his", "shoulders"]),
    ("chest", "胸部", "torso", "躯干", "She felt pain in her chest", "她感到胸口疼", ["She", "felt", "pain", "in", "her", "chest"]),
    ("back", "背部", "torso", "躯干", "Lie on your back", "仰面平躺", ["Lie", "on", "your", "back"]),
    ("waist", "腰部", "torso", "躯干", "The belt fits my waist", "这条腰带合我的腰", ["The", "belt", "fits", "my", "waist"]),
    ("abdomen", "腹部；肚子", "torso", "躯干", "The doctor pressed my abdomen", "医生按了按我的腹部", ["The", "doctor", "pressed", "my", "abdomen"]),
    ("navel", "肚脐", "torso", "躯干", "The baby has a tiny navel", "婴儿的肚脐很小", ["The", "baby", "has", "a", "tiny", "navel"]),
    ("hip", "臀部；胯部", "torso", "躯干", "She put her hands on her hips", "她双手叉腰", ["She", "put", "her", "hands", "on", "her", "hips"]),
    ("arm", "手臂", "upper_limb", "上肢", "He broke his left arm", "他摔断了左臂", ["He", "broke", "his", "left", "arm"]),
    ("armpit", "腋下", "upper_limb", "上肢", "Use deodorant on your armpits", "在腋下使用除臭剂", ["Use", "deodorant", "on", "your", "armpits"]),
    ("elbow", "肘部", "upper_limb", "上肢", "He leaned on his elbow", "他用胳膊肘撑着", ["He", "leaned", "on", "his", "elbow"]),
    ("wrist", "手腕", "upper_limb", "上肢", "She wore a watch on her wrist", "她手腕上戴着表", ["She", "wore", "a", "watch", "on", "her", "wrist"]),
    ("hand", "手", "upper_limb", "上肢", "Raise your right hand", "举起你的右手", ["Raise", "your", "right", "hand"]),
    ("palm", "手掌", "upper_limb", "上肢", "He held the coin in his palm", "他把硬币握在掌心", ["He", "held", "the", "coin", "in", "his", "palm"]),
    ("finger", "手指", "upper_limb", "上肢", "She cut her finger", "她割破了手指", ["She", "cut", "her", "finger"]),
    ("thumb", "大拇指", "upper_limb", "上肢", "Give me a thumbs up", "给我竖个大拇指", ["Give", "me", "a", "thumbs", "up"]),
    ("nail", "指甲", "upper_limb", "上肢", "She painted her nails red", "她把指甲涂成红色", ["She", "painted", "her", "nails", "red"]),
    ("leg", "腿", "lower_limb", "下肢", "The spider has eight legs", "蜘蛛有八条腿", ["The", "spider", "has", "eight", "legs"]),
    ("thigh", "大腿", "lower_limb", "下肢", "He felt pain in his thigh", "他大腿疼", ["He", "felt", "pain", "in", "his", "thigh"]),
    ("knee", "膝盖", "lower_limb", "下肢", "I hurt my knee", "我弄伤了膝盖", ["I", "hurt", "my", "knee"]),
    ("shin", "小腿前部", "lower_limb", "下肢", "He kicked the ball with his shin", "他用小腿前部踢球", ["He", "kicked", "the", "ball", "with", "his", "shin"]),
    ("calf", "小腿肚", "lower_limb", "下肢", "His calf muscles are strong", "他的小腿肌肉很强壮", ["His", "calf", "muscles", "are", "strong"]),
    ("ankle", "脚踝", "lower_limb", "下肢", "She twisted her ankle", "她扭伤了脚踝", ["She", "twisted", "her", "ankle"]),
    ("foot", "脚", "lower_limb", "下肢", "My left foot hurts", "我的左脚疼", ["My", "left", "foot", "hurts"]),
    ("heel", "脚后跟", "lower_limb", "下肢", "The shoe rubbed my heel", "鞋子磨脚后跟", ["The", "shoe", "rubbed", "my", "heel"]),
    ("toe", "脚趾", "lower_limb", "下肢", "I stubbed my toe", "我踢到脚趾了", ["I", "stubbed", "my", "toe"]),
    ("brain", "大脑", "internal", "内部器官", "Use your brain", "动动脑筋", ["Use", "your", "brain"]),
    ("heart", "心脏", "internal", "内部器官", "My heart beats fast", "我的心跳得很快", ["My", "heart", "beats", "fast"]),
    ("lung", "肺", "internal", "内部器官", "Smoking damages your lungs", "吸烟损害肺部", ["Smoking", "damages", "your", "lungs"]),
    ("stomach", "胃", "internal", "内部器官", "My stomach is growling", "我的肚子在咕咕叫", ["My", "stomach", "is", "growling"]),
    ("liver", "肝脏", "internal", "内部器官", "The liver filters blood", "肝脏过滤血液", ["The", "liver", "filters", "blood"]),
    ("bone", "骨骼", "internal", "内部器官", "This bone is broken", "这根骨头断了", ["This", "bone", "is", "broken"]),
    ("muscle", "肌肉", "internal", "内部器官", "Exercise builds muscle", "锻炼长肌肉", ["Exercise", "builds", "muscle"]),
    ("blood", "血液", "internal", "内部器官", "Blood flows in veins", "血液在血管里流动", ["Blood", "flows", "in", "veins"]),
]

KW_PH = {
    "hair": ("/heə(r)/", "/heɪr/"),
    "forehead": ("/ˈfɔːhed/", "/ˈfɔːrhed/"),
    "eye": ("/aɪ/", "/aɪ/"),
    "eyebrow": ("/ˈaɪbraʊ/", "/ˈaɪbraʊ/"),
    "eyelash": ("/ˈaɪlæʃ/", "/ˈaɪlæʃ/"),
    "ear": ("/ɪə(r)/", "/ɪr/"),
    "nose": ("/nəʊz/", "/noʊz/"),
    "cheek": ("/tʃiːk/", "/tʃiːk/"),
    "mouth": ("/maʊθ/", "/maʊθ/"),
    "lip": ("/lɪp/", "/lɪp/"),
    "tooth": ("/tuːθ/", "/tuːθ/"),
    "tongue": ("/tʌŋ/", "/tʌŋ/"),
    "chin": ("/tʃɪn/", "/tʃɪn/"),
    "neck": ("/nek/", "/nek/"),
    "shoulder": ("/ˈʃəʊldə(r)/", "/ˈʃoʊldər/"),
    "chest": ("/tʃest/", "/tʃest/"),
    "back": ("/bæk/", "/bæk/"),
    "waist": ("/weɪst/", "/weɪst/"),
    "abdomen": ("/ˈæbdəmən/", "/ˈæbdəmən/"),
    "navel": ("/ˈneɪv(ə)l/", "/ˈneɪv(ə)l/"),
    "hip": ("/hɪp/", "/hɪp/"),
    "arm": ("/ɑːm/", "/ɑːrm/"),
    "armpit": ("/ˈɑːmpɪt/", "/ˈɑːrmpɪt/"),
    "elbow": ("/ˈelbəʊ/", "/ˈelboʊ/"),
    "wrist": ("/rɪst/", "/rɪst/"),
    "hand": ("/hænd/", "/hænd/"),
    "palm": ("/pɑːm/", "/pɑːm/"),
    "finger": ("/ˈfɪŋɡə(r)/", "/ˈfɪŋɡər/"),
    "thumb": ("/θʌm/", "/θʌm/"),
    "nail": ("/neɪl/", "/neɪl/"),
    "leg": ("/leɡ/", "/leɡ/"),
    "thigh": ("/θaɪ/", "/θaɪ/"),
    "knee": ("/niː/", "/niː/"),
    "shin": ("/ʃɪn/", "/ʃɪn/"),
    "calf": ("/kɑːf/", "/kæf/"),
    "ankle": ("/ˈæŋk(ə)l/", "/ˈæŋk(ə)l/"),
    "foot": ("/fʊt/", "/fʊt/"),
    "heel": ("/hiːl/", "/hiːl/"),
    "toe": ("/təʊ/", "/toʊ/"),
    "brain": ("/breɪn/", "/breɪn/"),
    "heart": ("/hɑːt/", "/hɑːrt/"),
    "lung": ("/lʌŋ/", "/lʌŋ/"),
    "stomach": ("/ˈstʌmək/", "/ˈstʌmək/"),
    "liver": ("/ˈlɪvə(r)/", "/ˈlɪvər/"),
    "bone": ("/bəʊn/", "/boʊn/"),
    "muscle": ("/ˈmʌs(ə)l/", "/ˈmʌs(ə)l/"),
    "blood": ("/blʌd/", "/blʌd/"),
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


def load_meta() -> dict[str, dict]:
    meta = {}
    tsv = DIR / "build_body_tokens.tsv"
    with open(tsv, encoding="utf-8") as f:
        for row in csv.DictReader(f, delimiter="\t"):
            w = row["word"]
            meta[w] = row
    return meta


def main():
    meta = load_meta()
    sentences = []
    for idx, (kw, kw_zh, sec, sec_zh, orig, trans, toks) in enumerate(DATA, start=1):
        sid = f"HB_{idx:03d}"
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
                    "pattern_code": f"HB_{kw.upper()}",
                    "difficulty_level": 1,
                    "tags": ["human_body", sec, kw, "basic_vocabulary"],
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
        "unit_name": "人体词汇 - 头颈、躯干、四肢与内脏",
        "description": "涵盖头部、躯干、上肢、下肢及内部器官共 47 个基础词；附例句与逐词解析（释义、英/美音、词性）。",
        "category": "Human_Body",
        "code": "HB_01",
        "sentences": sentences,
    }
    out_path = DIR / "01_Human_Body.json"
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print("Wrote", out_path, "sentences:", len(sentences))


if __name__ == "__main__":
    main()
