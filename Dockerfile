FROM theos/theos:latest

WORKDIR /AppDrawer
COPY . .

RUN make package