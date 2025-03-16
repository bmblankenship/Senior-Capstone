import tkinter as tk
from tkinter import filedialog, messagebox
from tkinter import ttk
import shutil
import os
from PIL import Image, ImageTk
import matlab.engine
import threading
import socket
import pandas as pd  # Added for Excel validation


EXPECTED_HEADERS = {
    1: ["From Bus", "To Bus", "Branch Num", "Duration", "Other Considerations"],  # Example for Outage file
    2: ["Data Date", "Hour Number", "Demand (MW)", "Local Time at End of Hour", "Weighted Value of Max Load", "Unnamed: 5", "Unnamed: 6", "Unnamed: 7", "Unnamed: 8"],  # Example for Hourly Load file
    3: ["bus_i", "type", "Pd", "Qd", "Gs", "Bs", "area",
        "Vm", "Va", "baseKV", "zone", "Vmax", "Vmin", "Name"]  # Example for Case Data file
}


# Define expected column counts for each file type
EXPECTED_COLUMNS = {
    1: 5,   # Outages File
    2: 9,   # Hourly Load File
    3: 14   # Case Data File
}

# TCP server thread to listen for MATLAB log messages.
class TCPServerThread(threading.Thread):
    def __init__(self, host, port, callback):
        super().__init__()
        self.host = host
        self.port = port
        self.callback = callback  # function to call when data is received
        self.daemon = True  # ensure thread exits when main program does
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock.bind((self.host, self.port))
        self.sock.listen(1)

    def run(self):
        print(f"TCP Server: Listening on {self.host}:{self.port}")
        conn, addr = self.sock.accept()
        print(f"TCP Server: Connection established with {addr}")
        while True:
            data = conn.recv(1024)
            if not data:
                break
            # Decode bytes to string and call callback.
            self.callback(data.decode('utf-8'))
        conn.close()
        self.sock.close()


class MyApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Simulation Hours")
        self.root.geometry("800x600")

        # Store Excel file paths
        self.file_path_1 = None
        self.file_path_2 = None
        self.file_path_3 = None

        # Set MATLAB working directory
        self.matlab_script_directory = r"C:\Users\nwine\Downloads\matpower8.0\matpower8.0\CAPER_APP_TEST\Senior-Capstone-main"
        # Start MATLAB engine (without redirecting stdout/stderr)
        self.eng = matlab.engine.start_matlab()
        self.eng.cd(self.matlab_script_directory, nargout=0)

        # Initialize block dispatch state
        self.block_dispatch = 0  # Default to False
        self.generator_outages = 0  # Default to 0 (Off)


        # Start TCP server to receive MATLAB output
        self.start_tcp_server()

        # Create tabbed interface
        self.notebook = ttk.Notebook(self.root)
        self.main_tab = ttk.Frame(self.notebook)
        self.settings_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.main_tab, text="Main")
        self.notebook.add(self.settings_tab, text="Settings")
        self.notebook.pack(expand=1, fill="both")

        # Build tabs
        self.build_main_tab()
        self.build_settings_tab()

    def start_tcp_server(self):
        # Listen on localhost:12345 for MATLAB log messages.
        self.tcp_server_thread = TCPServerThread('127.0.0.1', 12345, self.handle_incoming_data)
        self.tcp_server_thread.start()

    def handle_incoming_data(self, data):
        # Schedule update of the text widget on the main thread.
        self.root.after(0, self.append_text, data)

    def append_text(self, text):
        """Append text to the MATLAB output Text widget."""
        self.matlab_output_text.config(state='normal')
        self.matlab_output_text.insert(tk.END, text)
        self.matlab_output_text.see(tk.END)
        self.matlab_output_text.config(state='disabled')

    def build_main_tab(self):
        # Label
        self.outage_planning_label = tk.Label(self.main_tab, text="Outage Planning System",
                                              font=("Helvetica", 24, "bold"))
        self.outage_planning_label.place(x=425, y=10)

        # Image
        try:
            self.image = Image.open("118-Bus System.png")
            self.image = self.image.resize((448, 280))
            self.image = ImageTk.PhotoImage(self.image)
            self.image_label = tk.Label(self.main_tab, image=self.image)
            self.image_label.place(x=400, y=50)
        except FileNotFoundError:
            messagebox.showerror("Error", "Image file '118-Bus System.png' not found.")

        # Start button
        self.start_button = tk.Button(self.main_tab, text="Start", font=("Bell MT", 18), command=self.run_matlab_code)
        self.start_button.place(x=800, y=350)

        # Drop areas for Excel files
        self.create_excel_drop_area(self.main_tab, "Outages File", 1, 50, 50)
        self.create_excel_drop_area(self.main_tab, "Hourly Load File", 2, 50, 175)
        self.create_excel_drop_area(self.main_tab, "Case Data File", 3, 50, 300)

        # Button to load Excel files
        self.load_data_button = tk.Button(self.main_tab, text="Load Excel Data", font=("Bell MT", 14),
                                          command=self.load_excel_data)
        self.load_data_button.place(x=50, y=400)

        # Text widget to display MATLAB output (read-only)
        self.matlab_output_text = tk.Text(self.main_tab, height=10, width=60, state='disabled')
        self.matlab_output_text.place(x=50, y=450)

    def build_settings_tab(self):
        self.verbose_label = tk.Label(self.settings_tab, text="Select VERBOSE Level:", font=("Arial", 14), anchor="w")
        self.verbose_label.place(x=50, y=50)

        self.verbose_values = [0, 1, 2]
        self.verbose_combobox = ttk.Combobox(self.settings_tab, values=self.verbose_values, state="readonly", width=10)
        self.verbose_combobox.set(0)
        self.verbose_combobox.place(x=265, y=55)

        self.method_label = tk.Label(self.settings_tab, text="Select Algorithm Type:", font=("Arial", 14), anchor="w")
        self.method_label.place(x=50, y=100)

        self.method_values = ["NR-SH", "NR", "NR-IH","NR-SC","NR-IP","FDXB","FDBX","FSOLVE","GS","ZG","PQSM", "ISUM","YSUM"]
        self.method_combobox = ttk.Combobox(self.settings_tab, values=self.method_values, state="readonly", width=10)
        self.method_combobox.set("NR-SH")
        self.method_combobox.place(x=250, y=105)

        self.time_label = tk.Label(self.settings_tab, text="Enter Simulation Hours (1-8760):", font=("Arial", 14),
                                   anchor="w")
        self.time_label.place(x=50, y=150)

        self.time_entry = tk.Entry(self.settings_tab, width=10)
        self.time_entry.place(x=330, y=155)

        self.start_hour_label = tk.Label(self.settings_tab, text="Enter Start Hour (1-8760):", font=("Arial", 14),
                                         anchor="w")
        self.start_hour_label.place(x=50, y=200)

        self.start_hour_entry = tk.Entry(self.settings_tab, width=10)
        self.start_hour_entry.place(x=330, y=205)

        # Block Dispatch toggle button
        self.block_dispatch_label = tk.Label(self.settings_tab, text="Block Dispatch:", font=("Arial", 14), anchor="w")
        self.block_dispatch_label.place(x=50, y=250)

        self.block_dispatch_button = tk.Button(self.settings_tab, text="Off", font=("Arial", 14),
                                               command=self.toggle_block_dispatch)
        self.block_dispatch_button.place(x=250, y=250)

        # Generator Outages toggle button
        self.generator_outages_label = tk.Label(self.settings_tab, text="Generator Outages:", font=("Arial", 14),
                                                anchor="w")
        self.generator_outages_label.place(x=50, y=300)

        self.generator_outages_button = tk.Button(self.settings_tab, text="Off", font=("Arial", 14),
                                                  command=self.toggle_generator_outages)
        self.generator_outages_button.place(x=250, y=300)



        # Button to create settings.txt file
        self.create_settings_button = tk.Button(self.settings_tab, text="Create settings.txt", font=("Arial", 14),
                                                command=self.create_settings_file)
        self.create_settings_button.place(x=50, y=350)

    def load_excel_data(self):
        """Loads Excel files into the specified folder."""
        try:
            if not all([self.file_path_1, self.file_path_2, self.file_path_3]):
                messagebox.showerror("Error", "Please select all three Excel files.")
                return
            custom_folder = self.matlab_script_directory
            os.makedirs(custom_folder, exist_ok=True)
            for i in range(1, 4):
                source_path = getattr(self, f"file_path_{i}")
                destination_path = os.path.join(custom_folder, os.path.basename(source_path))
                shutil.copy(source_path, destination_path)
            messagebox.showinfo("Success", "Excel files copied successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to load Excel files: {e}")

    def run_matlab_code(self):
        """Runs initialization.m only after verifying that settings.txt exists."""
        settings_file_path = os.path.join(self.matlab_script_directory, "settings.txt")
        if not os.path.exists(settings_file_path):
            messagebox.showerror("Error", "settings.txt file is missing. Please add it before running MATLAB.")
            return
        # Clear the text widget.
        self.matlab_output_text.config(state='normal')
        self.matlab_output_text.delete('1.0', tk.END)
        self.matlab_output_text.config(state='disabled')
        # Run the MATLAB code in a separate thread.
        threading.Thread(target=self._run_matlab_script).start()

    def _run_matlab_script(self):
        try:
            self.eng.run("initialization.m", nargout=0)
            print("MATLAB script 'initialization.m' executed successfully.")
        except Exception as e:
            print(f"Failed to execute MATLAB script: {e}")

    def create_excel_drop_area(self, parent, title, area_number, x_pos, y_pos):
        """Creates a drop area for Excel files."""
        label_title = tk.Label(parent, text=title, font=("Arial", 12, "bold"), fg="black")
        label_title.place(x=x_pos, y=y_pos - 30)
        drop_area = tk.Label(
            parent,
            text=f"Click to load Excel File {area_number} Here",
            bg="lightblue",
            fg="black",
            font=("Arial", 10, "bold"),
            relief="solid",
            bd=2,
            width=40,
            height=5,
        )
        drop_area.place(x=x_pos, y=y_pos)
        drop_area.bind("<Button-1>", lambda event, num=area_number: self.open_file_dialog(event, num))
        setattr(self, f"drop_area_{area_number}", drop_area)
        setattr(self, f"file_path_{area_number}", None)

    def open_file_dialog(self, event, area_number):
        file_path = filedialog.askopenfilename(title="Select Excel File", filetypes=[("Excel Files", "*.xlsx;*.xls")])
        if file_path:
            try:
                # Read the Excel file with pandas
                df = pd.read_excel(file_path)

                # Validate the number of columns
                num_columns = df.shape[1]
                expected_columns = EXPECTED_COLUMNS[area_number]

                if num_columns != expected_columns:
                    messagebox.showerror(
                        "Column Mismatch",
                        f"{os.path.basename(file_path)} should have {expected_columns} columns, but found {num_columns}."
                    )
                    return  # Reject file if column count is incorrect

                # Validate headers (first row of the file)
                expected_headers = EXPECTED_HEADERS[area_number]  # Get expected headers
                file_headers = list(df.columns)  # Extract actual headers from file

                if file_headers != expected_headers:
                    messagebox.showerror(
                        "Header Mismatch",
                        f"{os.path.basename(file_path)} has incorrect headers.\n\n"
                        f"Expected: {expected_headers}\n"
                        f"Found: {file_headers}"
                    )
                    return  # Reject file if headers do not match

                # If everything matches, assign file path
                setattr(self, f"file_path_{area_number}", file_path)
                file_name = os.path.basename(file_path)
                getattr(self, f"drop_area_{area_number}").config(text=f"Loaded: {file_name}")

            except Exception as e:
                messagebox.showerror("Error", f"Failed to read the file: {e}")

    def toggle_block_dispatch(self):
        """Toggles the Block Dispatch state and updates the button text."""
        self.block_dispatch = 1 if self.block_dispatch == 0 else 0  # Ensure it toggles between 0 and 1
        new_text = "On" if self.block_dispatch else "Off"
        self.block_dispatch_button.config(text=new_text)

    def toggle_generator_outages(self):
        """Toggles the Generator Outages state and updates the button text."""
        self.generator_outages = 1 if self.generator_outages == 0 else 0
        new_text = "On" if self.generator_outages else "Off"
        self.generator_outages_button.config(text=new_text)


    def create_settings_file(self):
        verbose_level = self.verbose_combobox.get()
        selected_method = self.method_combobox.get()
        time_value = self.time_entry.get()
        start_hour_value = self.start_hour_entry.get()
        block_dispatch_str = str(self.block_dispatch)
        generator_outages_str = str(self.generator_outages)
        settings_content = f"""*** SETTINGS FILE ***

*** VERBOSE ***
{verbose_level}

*** OUTAGE ***
{os.path.basename(self.file_path_1)}

*** LOAD ***
{os.path.basename(self.file_path_2)}

*** ALGORITHM ***
{selected_method}

*** CASE NAME ***
case118_CAPER_PeakLoad.m

*** End Hour ***
{time_value}

*** START HOUR ***
{start_hour_value}

*** CASE DATA ***
{os.path.basename(self.file_path_3)}

*** BLOCK DISPATCH ***
{block_dispatch_str}

*** GENERATOR OUTAGES ***
{generator_outages_str}

"""
        settings_file_path = os.path.join(self.matlab_script_directory, "settings.txt")
        try:
            with open(settings_file_path, "w") as f:
                f.write(settings_content)
            messagebox.showinfo("Success", "settings.txt file created successfully.")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to create settings.txt: {e}")


root = tk.Tk()
app = MyApp(root)
root.mainloop()


'weight bar'
'initialization.m'
'Add a warning for block dispatch'
'add read me for warning for block dispatch to code in seperate tab'