FROM public.ecr.aws/lambda/python:3.12
COPY . ${LAMBDA_TASK_ROOT}
WORKDIR /backend
ARG DEBIAN_FRONTEND=noninteractive

# Ensure dependencies required to run export-deps.sh are installed
RUN pip3 install wheel poetry --target "${LAMBDA_TASK_ROOT}"

# Generate requirements.txt using export-deps.sh
RUN source export-deps.sh

# Install dependencies from requirements.txt
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
