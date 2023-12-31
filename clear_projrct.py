import os
import shutil

def delete_files_in_directory(directory, target_folders):
    for root, dirs, files in os.walk(directory):
        for target_folder in target_folders:
            folder_path = os.path.join(root, target_folder)
            if os.path.exists(folder_path):
                for file_name in os.listdir(folder_path):
                    file_path = os.path.join(folder_path, file_name)
                    try:
                        if os.path.isfile(file_path):
                            os.unlink(file_path)
                            print(f"Deleted {file_path}.")
                        elif os.path.isdir(file_path):
                            shutil.rmtree(file_path)
                            print(f"Deleted {file_path}.")
                    except Exception as e:
                        print(f"Failed to delete {file_path}. Error: {e}")
def delete_run_log_files(directory="."):
    for root, dirs, files in os.walk(directory):
        for file_name in files:
            if file_name == "run.log":
                file_path = os.path.join(root, file_name)
                try:
                    os.remove(file_path)
                    print(f"Deleted: {file_path}")
                except Exception as e:
                    print(f"Failed to delete {file_path}. Error: {e}")

if __name__ == "__main__":
    current_directory = os.getcwd()
    target_folders = ["bak", "logbackup"]

    delete_files_in_directory(current_directory, target_folders)
    delete_run_log_files(current_directory)
    print("Deletion completed.")
