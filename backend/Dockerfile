FROM public.ecr.aws/lambda/python:3.12
COPY . ${LAMBDA_TASK_ROOT}
WORKDIR ${LAMBDA_TASK_ROOT}/backend
ARG DEBIAN_FRONTEND=noninteractive

# Verify that the script exists
RUN ls -al ${LAMBDA_TASK_ROOT}/backend

# Ensure dependencies required to run export-deps.sh are installed
RUN pip3 install wheel poetry --target "${LAMBDA_TASK_ROOT}"

# Make export-deps.sh executable and run it
RUN chmod +x export-deps.sh && ./export-deps.sh

# Install dependencies from requirements.txt
RUN pip install -r ${LAMBDA_TASK_ROOT}/requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
