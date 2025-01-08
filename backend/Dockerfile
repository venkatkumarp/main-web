##FROM public.ecr.aws/lambda/python:3.12

# Install Poetry
##RUN pip install poetry

# Copy the entire project into the container
##COPY . ${LAMBDA_TASK_ROOT}

# Set working directory to backend folder
##WORKDIR ${LAMBDA_TASK_ROOT}/backend

# Install wheel package
##RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"

# Run poetry export to generate requirements.txt
##RUN poetry export --without-hashes -o requirements.txt

# Install dependencies from the generated requirements.txt
##RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

##CMD ["start.handler"]

FROM public.ecr.aws/lambda/python:3.12

RUN yum install -y unixODBC unixODBC-devel

RUN pip install poetry

COPY . ${LAMBDA_TASK_ROOT}

WORKDIR ${LAMBDA_TASK_ROOT}/backend

RUN pip3 install wheel --target "${LAMBDA_TASK_ROOT}"

RUN poetry export --without-hashes -o requirements.txt

RUN pip install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"

CMD ["start.handler"]
