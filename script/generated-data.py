import datetime

# 定义参数
sampling_rate = 8192  # 采样频率，每秒 8192 次
sampling_duration_hours = 1  # 采样时间为 1 小时

# 计算总采样点数
total_samples = sampling_rate * 3600 * sampling_duration_hours

# 准备数据并写入文件
with open("data.txt", "w") as file:
    # 写入表头
    file.write("stamp content\n")

    # 生成时间戳和随机内容数据
    for i in range(total_samples):
        timestamp = datetime.datetime.now() + datetime.timedelta(
            seconds=i / sampling_rate
        )
        content = f"Event {i + 1}"  # 随意的内容，可以根据实际需求更改
        stamp = timestamp.strftime("%H:%M:%S.%f")[:-3]  # 格式化时间戳，精确到毫秒

        # 写入到文件
        file.write(f"{stamp} {content}\n")

print(f"数据已成功写入 data.txt 文件，共 {total_samples} 条数据。")
