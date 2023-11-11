import os

# 搜索文件并将相对路径写入文本文件
def search_and_write_file_paths(folder_path, file_extension, output_file):
    with open(output_file, 'w') as output:
        for foldername, subfolders, filenames in os.walk(folder_path):
            for filename in filenames:
                if filename.endswith(file_extension):
                    relative_path = os.path.relpath(os.path.join(foldername, filename), folder_path)
                    output.write(relative_path + '\n')

if __name__ == '__main__':
    folder_path = os.getcwd()  # 当前文件夹路径
    file_extension = ('.v', '.sv','.svh','.vh')  # 文件扩展名
    output_file = 'verible.filelist'  # 输出文件名

    search_and_write_file_paths(folder_path, file_extension, output_file)
    print(f'文件路径已写入到 {output_file}')
