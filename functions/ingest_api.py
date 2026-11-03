import kagglehub
from kagglehub import KaggleDatasetAdapter
from os import path

project_path = path.dirname(path.dirname(path.abspath(__file__)))
data_path = path.join(project_path, "data")
print("Data path:", data_path)

file_path = "Amazon.csv" 

df = kagglehub.dataset_load(
    KaggleDatasetAdapter.PANDAS,
    "rohiteng/amazon-sales-dataset",
    file_path
  )
    
if df is not None:
  df.to_csv(path.join(data_path, "Amazon.csv"), index=False)  # Save the DataFrame to a CSV file
else:
  print("Failed to load the dataset.")

print("First 5 records:", df.head())