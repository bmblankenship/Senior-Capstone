import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter import ttk  # Import ttk for the combobox
import shutil
import os
import pandas as pd
from PIL import Image, ImageTk
import matlab.engine  # To interact with MATLAB from Python


class MyApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Outage Planning System")
        self.root.geometry("640x480")

        # Store Excel file data and paths
        self.excel_data_1 = None
        self.excel_data_2 = None
        self.excel_data_3 = None
        self.excel_file_path_1 = None
        self.excel_file_path_2 = None
        self.excel_file_path_3 = None

        # Initialize MATLAB engine
        self.eng = matlab.engine.start_matlab()

        # Set MATLAB working directory to the MATLAB root folder (or the folder where your scripts are located)
        self.matlab_script_directory = r"C:\Users\nwine\Downloads\matpower8.0\matpower8.0\CAPER_APP_TEST"
        self.eng.cd(self.matlab_script_directory, nargout=0)  # Change MATLAB working directory

        # Label
        self.outage_planning_label = tk.Label(root, text="Outage Planning System", font=("Helvetica", 24, "bold"))
        self.outage_planning_label.place(x=400, y=0)

        # Image (using Pillow to load and handle the image)
        try:
            self.image = Image.open("118-Bus System.png")  # Use Pillow to open the image
            self.image = self.image.resize((448, 280))  # Resize the image as needed
            self.image = ImageTk.PhotoImage(self.image)  # Convert it to a Tkinter-compatible image
            self.image_label = tk.Label(root, image=self.image)
            self.image_label.place(x=350, y=50)
        except FileNotFoundError:
            messagebox.showerror("Error", "Image file '118-Bus System.png' not found.")

        # Start button
        self.start_button = tk.Button(root, text="Start", font=("Bell MT", 18), command=self.run_matlab_code)
        self.start_button.place(x=700, y=370)

        # Drop areas for Excel files (three areas for three files)
        self.create_excel_drop_area(1, "Outages", 0, 50)
        self.create_excel_drop_area(2, "HourlyLoad", 0, 150)
        self.create_excel_drop_area(3, "CaseData", 0, 250)

        # Button to load the Excel files
        self.load_data_button = tk.Button(root, text="Load Excel Data", font=("Bell MT", 14),
                                          command=self.load_excel_data)
        self.load_data_button.place(x=50, y=380)

        # Drop-down menu for VERBOSE selection
        self.verbose_label = tk.Label(root, text="Select VERBOSE Level", font=("Arial", 14))
        self.verbose_label.place(x=250, y=380)

        self.verbose_values = [0, 1, 2]  # Possible VERBOSE values
        self.verbose_combobox = ttk.Combobox(root, values=self.verbose_values, state="readonly", width=10)
        self.verbose_combobox.set(0)  # Default value is 0
        self.verbose_combobox.place(x=460, y=385)

        # Store VERBOSE level selected from the drop-down menu
        self.verbose_level = 0  # Default value

    def create_excel_drop_area(self, area_number, label_text, x_pos, y_pos):
        """Create a drop area for Excel files."""
        label = tk.Label(self.root, text=label_text, bg="lightgrey", width=40, height=5)
        label.place(x=x_pos, y=y_pos)
        label.bind("<Button-1>", lambda event, num=area_number: self.open_file_dialog(event, num))
        setattr(self, f"drop_area_{area_number}", label)
        setattr(self, f"file_path_{area_number}", None)

    def open_file_dialog(self, event, area_number):
        """Open file dialog to select an Excel file for the given area."""
        file_path = filedialog.askopenfilename(title="Select Excel File", filetypes=[("Excel Files", "*.xlsx;*.xls")])

        if file_path:  # If a file is selected
            setattr(self, f"file_path_{area_number}", file_path)
            # Update the label text with the selected file name
            file_name = os.path.basename(file_path)
            getattr(self, f"drop_area_{area_number}").config(text=f"Loaded: {file_name}")
        else:
            messagebox.showinfo("No File", "No file selected.")

    def load_excel_data(self):
        """Copy the selected Excel files to the custom directory."""
        try:
            # Check if all three files are selected
            if not all([getattr(self, f"file_path_{i}") for i in range(1, 4)]):
                messagebox.showerror("Error", "Please select all three Excel files.")
                return

            # Define the custom folder path
            custom_folder = r"C:\Users\nwine\Downloads\matpower8.0\matpower8.0\CAPER_APP_TEST"
            if not os.path.exists(custom_folder):
                os.makedirs(custom_folder)  # Create the directory if it doesn't exist

            # Copy the Excel files to the custom folder
            for i in range(1, 4):
                source_path = getattr(self, f"file_path_{i}")
                destination_path = os.path.join(custom_folder, os.path.basename(source_path))
                shutil.copy(source_path, destination_path)  # Copy the file to the custom folder
                messagebox.showinfo("File Copied", f"Excel file {i} copied to: {destination_path}")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load Excel files: {e}")

    def run_matlab_code(self):
        """Run MATLAB code after all Excel files are loaded."""
        # Get the selected VERBOSE level from the combobox
        self.verbose_level = int(self.verbose_combobox.get())

        # Ensure all Excel data is loaded before running MATLAB code
        if all([getattr(self, f"file_path_{i}") for i in range(1, 4)]):
            try:
                # Get the file paths in the correct order
                excel_file_1 = getattr(self, "file_path_1")  # File 1 (Load Case)
                excel_file_2 = getattr(self, "file_path_2")  # File 2 (Case Data)
                excel_file_3 = getattr(self, "file_path_3")  # File 3 (Outages)

                # Define the MATLAB script path
                matlab_script = os.path.join(self.matlab_script_directory, 'case118_CAPER_PeakLoad.m')

                # Construct the MATLAB code string with proper quoting and path handling
                matlab_code = (
                    f"standalone(186, {self.verbose_level}, '{excel_file_1}', '{excel_file_2}', 'NR', '{matlab_script}', 5);"
                )

                # Run the MATLAB code
                self.eng.eval(matlab_code, nargout=0)

                messagebox.showinfo("MATLAB Code Executed", "MATLAB code has been executed successfully.")
            except Exception as e:
                messagebox.showerror("MATLAB Error", f"Failed to run MATLAB code: {e}")
        else:
            messagebox.showerror("Error", "Please load all Excel files before running MATLAB code.")


# Create the root window
root = tk.Tk()

# Initialize the application
app = MyApp(root)

# Run the Tkinter event loop
root.mainloop()


'add algorithm type drop down menu'
'add simulation our input and make it require a number of 1-8760 and if its not within that peramter make it give an error'