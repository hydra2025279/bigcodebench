#!/bin/bash  
  
set -e  # Exit on error  
  
echo "Step 1: Building custom Docker image..."  
  
docker build -f Docker/Evaluate.Dockerfile . -t bigcodebench-custom:latest  
  
# ============================================  
# STEP 2: Tìm file samples vừa generate  
# ============================================  
SAMPLES_FILE=$(ls -t bcb_results/${MODEL}--*--bigcodebench-${SPLIT}--${BACKEND}-*.jsonl | head -1)  
  
if [ -z "$SAMPLES_FILE" ]; then  
    echo "Error: Samples file not found!"  
    exit 1  
fi  
  
echo "Found samples file: $SAMPLES_FILE"  
  
# ============================================  
# STEP 5: Evaluate với Docker custom  
# ============================================  
echo "Step 2: Evaluating with custom Docker image..."  
  
docker run -v $(pwd):/app bigcodebench-custom:latest \  
    --execution local \  
    --split $SPLIT \  
    --subset $SUBSET \  
    --samples $SAMPLES_FILE  
  
# ============================================  
# STEP 6: Kiểm tra kết quả  
# ============================================  
echo "Step 3: Checking results..."  
  
EVAL_RESULTS="${SAMPLES_FILE%.jsonl}_eval_results.json"  
PASS_K_RESULTS="${SAMPLES_FILE%.jsonl}_pass_at_k.json"  
  
if [ -f "$EVAL_RESULTS" ]; then  
    echo "✓ Evaluation results: $EVAL_RESULTS"  
fi  
  
if [ -f "$PASS_K_RESULTS" ]; then  
    echo "✓ Pass@k results: $PASS_K_RESULTS"  
    cat "$PASS_K_RESULTS"  
fi  
  
# ============================================  
# STEP 4: Cleanup (optional)  
# ============================================  
echo "Step 4: Cleanup..."  
  
pids=$(ps -u $(id -u) -o pid,comm | grep 'bigcodebench' | awk '{print $1}')  
if [ -n "$pids" ]; then   
    echo $pids | xargs -r kill  
fi  
  
rm -rf /tmp/*  
  
echo "Done! All results are in bcb_results/"