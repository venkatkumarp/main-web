FROM public.ecr.aws/lambda/python:3.12
COPY . ${LAMBDA_TASK_ROOT}
WORKDIR /backend
ARG DEBIAN_FRONTEND=noninteractive

RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"
RUN source export-deps.sh
COPY /backend/requirements.txt /backend/requirements.txt
RUN pip install -r /backend/requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
