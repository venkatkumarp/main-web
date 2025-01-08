##FROM public.ecr.aws/lambda/python:3.12

# RUN yum install unixODBC

##RUN pip install poetry

##COPY . ${LAMBDA_TASK_ROOT}

##WORKDIR ${LAMBDA_TASK_ROOT}/backend

##RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"

# RUN poetry export --without-hashes -o requirements.txt
##COPY requirements.txt requirements.txt

##RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

##CMD ["start.handler"]
####
FROM public.ecr.aws/lambda/python:3.12
RUN dnf update -y && \
    dnf install -y unixODBC unixODBC-devel

# Install pyodbc
#RUN pip install pyodbc



RUN pip install poetry

COPY . ${LAMBDA_TASK_ROOT}

WORKDIR ${LAMBDA_TASK_ROOT}/backend

RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"

# RUN poetry export --without-hashes -o requirements.txt
COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
