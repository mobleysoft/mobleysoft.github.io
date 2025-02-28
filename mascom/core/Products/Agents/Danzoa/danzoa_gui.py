import tkinter as tk
from tkinter import messagebox
from danzoa_core import samples, generate_patterns, sequencer_playback, save_remix

def preview_sample(sample_key):
    """
    Play a sample preview.
    """
    track, sample_type = sample_key.split("_")
    print(f"Playing sample: {track} ({sample_type})")

def toggle_autonomy():
    """
    Hand over full control to the agent.
    """
    print("Agent is generating the remix autonomously...")
    generate_patterns()
    sequencer_playback()
    save_remix()
    messagebox.showinfo("Danzoa", "Remix generation complete! Check the output folder for the final mix.")

def setup_gui():
    """
    Sets up the GUI for Danzoa's virtual MPC and control interface.
    """
    root = tk.Tk()
    root.title("Danzoa AI DJ System")
    root.geometry("1000x600")

    # Frame for MPC pads
    pad_frame = tk.Frame(root)
    pad_frame.pack(pady=10)
    tk.Label(pad_frame, text="Virtual MPC Pads", font=("Arial", 18)).pack()

    # Create MPC pads dynamically based on available samples
    for i, track in enumerate(samples.keys()):
        row = tk.Frame(pad_frame)
        row.pack(side=tk.TOP, pady=10)
        tk.Label(row, text=f"{track}", font=("Arial", 14)).pack(side=tk.LEFT, padx=10)
        for sample_type in samples[track]:
            sample_key = f"{track}_{sample_type}"
            btn = tk.Button(
                row,
                text=f"{sample_type.capitalize()}",
                width=12,
                height=2,
                command=lambda k=sample_key: preview_sample(k),
            )
            btn.pack(side=tk.LEFT, padx=5)

    # Autonomy toggle
    autonomy_frame = tk.Frame(root)
    autonomy_frame.pack(pady=20)
    tk.Button(
        autonomy_frame,
        text="Enable Full Agent Control",
        font=("Arial", 16),
        bg="green",
        fg="white",
        command=toggle_autonomy,
    ).pack()

    # Exit button
    exit_frame = tk.Frame(root)
    exit_frame.pack(pady=10)
    tk.Button(
        exit_frame,
        text="Exit",
        font=("Arial", 14),
        bg="red",
        fg="white",
        command=root.destroy,
    ).pack()

    root.mainloop()

if __name__ == "__main__":
    setup_gui()
