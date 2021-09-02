import os
import shutil

root_dir = "/home/me/StudioProjects/web_app_sample/assets/images"
out_dir = "/home/me/images"

os.makedirs(out_dir, exist_ok=True)

'''
// リーチ牌画像取得の簡単さのため、並び順を変更する。
// Converted direction 0: 打牌（上向）1: 打牌（左向）2: 打牌（下向）3: 打牌（右向）4: 自牌（上向）
var converted = 0;
if (direction == 0) converted = 4;
if (direction == 1) converted = 0;
if (direction == 2) converted = 2;
if (direction == 3) converted = 1;
if (direction == 4) converted = 3;
'''

def copy(sub_dir, prefix, max_value, type):
    for v in range(max_value):
        for i in range(5):
            if (i == 0): j = 4
            if (i == 1): j = 0
            if (i == 2): j = 2
            if (i == 3): j = 1
            if (i == 4): j = 3
            src_path = f"{root_dir}/{sub_dir}_all/{prefix}{v+1}_{i}.gif"
            dst_path = f"{out_dir}/{type}_{v}_{j}.gif"
            shutil.copyfile(src_path, dst_path)

copy("manzu", "p_ms", 9, 0)
copy("pinzu", "p_ps", 9, 1)
copy("sozu", "p_ss", 9, 2)
copy("tupai", "p_ji", 7, 3)
copy("ms", "p_bk", 1, 4)

def copy_stage(dst, src):
    src_path = f"{root_dir}/ms_all/{src}.gif"
    dst_path = f"{out_dir}/{dst}.gif"
    shutil.copyfile(src_path, dst_path)

copy_stage("stage_0_0", "c_e_1")
copy_stage("stage_0_1", "c_e_4")
copy_stage("stage_0_2", "c_e_3")
copy_stage("stage_0_3", "c_e_2")

copy_stage("stage_1_0", "c_s_1")
copy_stage("stage_1_1", "c_s_4")
copy_stage("stage_1_2", "c_s_3")
copy_stage("stage_1_3", "c_s_2")

copy_stage("stage_2_0", "c_w_1")
copy_stage("stage_2_1", "c_w_4")
copy_stage("stage_2_2", "c_w_3")
copy_stage("stage_2_3", "c_w_2")

copy_stage("stage_3_0", "c_n_1")
copy_stage("stage_3_1", "c_n_4")
copy_stage("stage_3_2", "c_n_3")
copy_stage("stage_3_3", "c_n_2")
