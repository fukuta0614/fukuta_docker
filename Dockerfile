FROM nvidia/cuda:8.0-cudnn7-devel

RUN \
 apt-get update -y && \
 apt-get upgrade -y && \
 apt-get install -y build-essential && \
 apt-get install -y software-properties-common

RUN apt-get install -y sudo tree openssh-server tmux curl git htop man unzip vim wget zsh libssl-dev openssl zlib1g-dev sqlite3

# openslide
RUN apt-get install -y libopenslide0

# nccl
RUN git clone https://github.com/NVIDIA/nccl.git
RUN cd nccl && make CUDA_HOME=/usr/local/cuda && mkdir /usr/local/nccl && make PREFIX=/usr/local/nccl install
RUN rm -rf nccl

# for sshd
RUN sed -i 's/.*session.*required.*pam_loginuid.so.*/session optional pam_loginuid.so/g' /etc/pam.d/sshd
RUN mkdir /var/run/sshd

# create user fukuta_dev
RUN useradd -m -u 1002 fukuta \
    && echo "fukuta ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && echo 'fukuta:qwe123qwe' | chpasswd
RUN chsh -s /usr/bin/zsh fukuta

# locale
RUN apt-get -y install locales
RUN locale-gen en_US.UTF-8

# user
USER fukuta
WORKDIR /home/fukuta
ENV HOME /home/fukuta
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8


# enable ssh with key
RUN mkdir /home/fukuta/.ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCi2lVOlwPTxHiTkCiVQpdBDBlpoSxR9PQnNJD/HQ0zOm6y3XLtFpEsdb4ELpCKnBNAW8djQtG2h6en5q3cB04wnrdVIJY/2Cbr44CXuoRYsyQ6uKst7frPezlp7h4YMb3IhRoJ4h5wIK19zyXfdUHk6CozkjVOLp4hSkxiV3GKWWMaZXBwnkRkmors7UBFa6pEqu0PfP2IwmmvfO5PtQa7hvaluwu2o6iRegSwf5T8DH5mzghABmlYxJhcSA/dAhqiyoKrDAqepROEe4rXHWiVLv5PNwEV4iNmvRlN2x0O0pZGuJ5fvMzRdQfiHa7f20bW55uaa+rLoPsMenTE2yf fukuta-mil@fukuta-mil-mac.local" > /home/fukuta/.ssh/authorized_keys

# dotfiles
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN git clone https://github.com/fukuta0614/dotfiles.git ~/.dotfiles
RUN cd .dotfiles && zsh ./install.sh

# env
RUN echo 'export PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:$PATH' >> .zshrc
RUN echo 'export LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64:$LD_LIBRARY_PATH' >> .zshrc
RUN echo 'export LIBRARY_PATH=/usr/local/cuda/lib64/stubs:$LIBRARY_PATH' >> .zshrc

RUN echo 'export NCCL_ROOT="/usr/local/nccl"' >> .zshrc
RUN echo 'export CPATH="$NCCL_ROOT/include:$CPATH"' >> .zshrc
RUN echo 'export LD_LIBRARY_PATH="$NCCL_ROOT/lib/:$LD_LIBRARY_PATH"' >> .zshrc
RUN echo 'export LIBRARY_PATH="$NCCL_ROOT/lib/:$LIBRARY_PATH"' >> .zshrc

# Python (pyenv)
RUN git clone https://github.com/yyuu/pyenv.git ~/.pyenv
RUN ~/.pyenv/bin/pyenv install anaconda3-4.3.0
RUN ~/.pyenv/bin/pyenv global anaconda3-4.3.0

# pip
RUN /home/fukuta/.pyenv/shims/pip install chainer
RUN /home/fukuta/.pyenv/shims/pip install cupy
RUN /home/fukuta/.pyenv/shims/pip install openslide-python
RUN /home/fukuta/.pyenv/shims/pip install tensorflow
RUN /home/fukuta/.pyenv/shims/pip install percol

# conda
RUN /home/fukuta/.pyenv/shims/conda install -c menpo opencv3

# volumes
RUN mkdir /home/fukuta/work_space/

# for ssh
USER root
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
