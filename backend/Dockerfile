FROM public.ecr.aws/lambda/python:3.12

WORKDIR ${LAMBDA_TASK_ROOT}
ARG DEBIAN_FRONTEND=noninteractive

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

# Copy the rest of the application
COPY . .

CMD ["start.handler"]
