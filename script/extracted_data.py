import datetime

# 定义要提取的时间范围（假设要提取从第10秒到第40秒的数据）
start_time = datetime.datetime.strptime("17:32:19.000", "%H:%M:%S.%f")
end_time = datetime.datetime.strptime("17:32:49.000", "%H:%M:%S.%f")

# 读取data.txt文件并提取指定时间范围内的数据
with open("data.txt", "r") as file:
    lines = file.readlines()

# 写入提取的数据到新文件中
with open("extracted_data.txt", "w") as new_file:
    new_file.write("stamp content\n")  # 写入表头

    for line in lines[1:]:  # 跳过表头，从第二行开始遍历
        parts = line.strip().split(" ")
        timestamp = datetime.datetime.strptime(parts[0], "%H:%M:%S.%f")

        if start_time <= timestamp <= end_time:
            new_file.write(line)

print("提取的数据已成功写入 extracted_data.txt 文件。")
