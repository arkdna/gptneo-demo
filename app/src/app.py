from flask import Flask, request, jsonify, render_template
import sys
import logging
from tqdm import tqdm

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

app = Flask(__name__)

print("Starting app initialization...")
logger.debug("Debug logging enabled")

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
        print("Starting model load (this will download ~5GB on first run)...")
        try:
            model = GPTNeoForCausalLM.from_pretrained(
                "EleutherAI/gpt-neo-1.3B",
                low_cpu_mem_usage=False,
                torch_dtype=torch.float32,
                device_map=None,
                local_files_only=False,
                progress_bar=True
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
        return GPT2Tokenizer.from_pretrained("EleutherAI/gpt-neo-1.3B")

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
    return render_template('index.html')

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    print("Starting Flask server...")
    app.run(host='0.0.0.0', port=5000, debug=True) 