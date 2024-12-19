FROM public.ecr.aws/lambda/python:3.12

# Set working directory
WORKDIR ${LAMBDA_TASK_ROOT}

# Copy the backend directory
COPY ./backend ./backend

# Set working directory to backend
WORKDIR ${LAMBDA_TASK_ROOT}/backend

# Run export-deps.sh to generate requirements.txt
RUN bash export-deps.sh

# Install dependencies
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy any remaining files
COPY . ${LAMBDA_TASK_ROOT}

CMD ["start.handler"]
