FROM elmarit/harbour:3.2 as builder

RUN apt-get update && apt-get install -y apt-utils
RUN apt-get install -y \
        libfcgi-dev \
        libapache2-mod-fcgid \
        git
COPY . /src
WORKDIR /src
RUN git clone https://github.com/EricLendvai/Harbour_FastCGI/
RUN git clone https://github.com/EricLendvai/Harbour_VFP/
RUN git clone https://github.com/EricLendvai/Harbour_ORM/

ENV BuildMode release
ENV HB_COMPILER gcc
ENV HB_VFP_ROOT /src/Harbour_VFP/
ENV HB_ORM_ROOT /src/Harbour_ORM/
ENV FastCGIRootPath ./Harbour_FastCGI/

# Build ORM and VFP libraries
WORKDIR /src/Harbour_VFP
RUN chmod +x ./BuildLIB.sh
ENV LIBName hb_vfp
RUN ./BuildLIB.sh

WORKDIR /src/Harbour_ORM
RUN chmod +x ./BuildLIB.sh
ENV LIBName hb_orm
RUN ./BuildLIB.sh

# Build DataWharf
WORKDIR /src
RUN mkdir -p build/lin64/clang/release/hbmk2
ENV EXEName DataWharf
ENV SiteRootFolder /var/www/Harbour_websites/fcgi_DataWharf/
RUN  hbmk2 DataWharf_linux.hbp -w3 -static

