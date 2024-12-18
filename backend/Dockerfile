FROM public.ecr.aws/lambda/python:3.12
ARG DEBIAN_FRONTEND=noninteractive
WORKDIR /backend
COPY . .
RUN chmod +x export-deps.sh && ./export-deps.sh
#COPY . ${LAMBDA_TASK_ROOT}
RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"
RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]


#RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"
#RUN source export-deps.sh
#COPY ./requirements.txt ./requirements.txt
#RUN pip install -r ./requirements.txt --target "${LAMBDA_TASK_ROOT}"

#CMD ["start.handler"]
