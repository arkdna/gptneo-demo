from flask import Flask, request, jsonify, render_template
from transformers import GPTNeoForCausalLM, GPT2Tokenizer
import torch
import gc
from functools import lru_cache

app = Flask(__name__)

# CPU Optimization settings
torch.set_num_threads(4)  # Adjust based on your CPU cores, don't use all cores
torch.set_grad_enabled(False)  # Ensure gradients are disabled for inference

# Load model with optimizations
@lru_cache(maxsize=1)  # Cache the model loading
def load_model():
    model = GPTNeoForCausalLM.from_pretrained(
        "EleutherAI/gpt-neo-1.3B",
        low_cpu_mem_usage=True,
        torch_dtype=torch.float32,
        device_map='auto'
    )
    model.eval()
    return model

@lru_cache(maxsize=1)
def load_tokenizer():
    return GPT2Tokenizer.from_pretrained("EleutherAI/gpt-neo-1.3B")

# Initialize model and tokenizer
model = load_model()
tokenizer = load_tokenizer()

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/generate', methods=['POST'])
def generate():
    try:
        data = request.json
        prompt = data.get('prompt', '')
        
        # Tokenize with max length limit
        input_ids = tokenizer.encode(prompt, return_tensors='pt', truncation=True, max_length=512)
        
        # Generate with memory-efficient settings
        with torch.no_grad():
            output = model.generate(
                input_ids,
                max_length=100,  # Reduced for faster response
                num_return_sequences=1,
                no_repeat_ngram_size=2,
                temperature=0.7,
                pad_token_id=tokenizer.eos_token_id,
                do_sample=True,
                top_k=50,
                top_p=0.95
            )
        
        generated_text = tokenizer.decode(output[0], skip_special_tokens=True)
        
        # Clean up memory
        gc.collect()
        torch.cuda.empty_cache() if torch.cuda.is_available() else None
        
        return jsonify({
            'status': 'success',
            'response': generated_text
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    memory_stats = {
        'allocated': torch.cuda.memory_allocated() if torch.cuda.is_available() else 0,
        'cached': torch.cuda.memory_reserved() if torch.cuda.is_available() else 0
    }
    return jsonify({
        'status': 'healthy',
        'device': 'cpu',
        'threads': torch.get_num_threads(),
        'memory': memory_stats
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 