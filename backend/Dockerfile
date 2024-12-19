FROM public.ecr.aws/lambda/python:3.12
COPY . ${LAMBDA_TASK_ROOT}
WORKDIR /backend
ARG DEBIAN_FRONTEND=noninteractive

RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"
RUN ./export-deps.sh
COPY ./requirements.txt ./requirements.txt
RUN pip install -r ./requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
