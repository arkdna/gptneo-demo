from flask import Flask, request, jsonify, render_template
import sys
import logging
import requests
from tqdm import tqdm
import os

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Set up the Flask app with explicit template folder
template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'templates'))
app = Flask(__name__, template_folder=template_dir)

print("Starting app initialization...")
logger.debug("Debug logging enabled")

def download_with_progress(url, filename):
    response = requests.get(url, stream=True)
    total_size = int(response.headers.get('content-length', 0))
    block_size = 1024
    progress_bar = tqdm(total=total_size, unit='iB', unit_scale=True)
    
    with open(filename, 'wb') as f:
        for data in response.iter_content(block_size):
            progress_bar.update(len(data))
            f.write(data)
    progress_bar.close()

try:
    print("Importing torch and transformers...")
    from transformers import GPTNeoForCausalLM, GPT2Tokenizer
    import torch
    from functools import lru_cache
    print("Imports successful")

    # CPU Optimization settings
    print("Configuring torch settings...")
    torch.set_num_threads(4)
    torch.set_grad_enabled(False)
    print("Torch configured")

    @lru_cache(maxsize=1)
    def load_model():
        print("Starting model load (this will download ~125M model for testing)...")
        try:
            model = GPTNeoForCausalLM.from_pretrained(
                "EleutherAI/gpt-neo-125M",  # Smaller model for testing
                low_cpu_mem_usage=False,
                torch_dtype=torch.float32,
                device_map=None
            )
            print("Model loaded successfully")
            model.eval()
            return model
        except Exception as e:
            print(f"Error loading model: {str(e)}")
            logger.exception("Model loading failed")
            raise

    @lru_cache(maxsize=1)
    def load_tokenizer():
        print("Loading tokenizer...")
        return GPT2Tokenizer.from_pretrained("EleutherAI/gpt-neo-125M")  # Match the model size

    print("Initializing model and tokenizer...")
    model = load_model()
    tokenizer = load_tokenizer()
    print("Initialization complete")

except Exception as e:
    print(f"Error during initialization: {str(e)}")
    logger.exception("Initialization failed")
    raise

@app.route('/')
def home():
    print(f"Looking for templates in: {template_dir}")  # Debug print
    return render_template('index.html')

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    print("Starting Flask server...")
    app.run(host='0.0.0.0', port=5000, debug=True) 