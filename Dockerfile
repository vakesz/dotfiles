FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install core packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        git \
        openssh-server \
        curl \
        zsh \
        locales \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set up locales (optional, improves shell experience)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set up SSH
RUN mkdir /var/run/sshd

# Add dev user (change name if you wish)
ARG USERNAME=vakesz
RUN useradd -m -s /bin/zsh $USERNAME && \
    usermod -aG sudo $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Prepare .ssh directory with proper permissions for SSH key auth
RUN mkdir -p /home/$USERNAME/.ssh && \
    chown $USERNAME:$USERNAME /home/$USERNAME/.ssh && \
    chmod 700 /home/$USERNAME/.ssh

# Disable password and challenge-response SSH auth
RUN sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?UsePAM .*/UsePAM no/' /etc/ssh/sshd_config

# Clone your dotfiles and run install script as the user
USER $USERNAME
WORKDIR /home/$USERNAME
RUN git clone https://github.com/vakesz/dotfiles.git ~/dotfiles && \
    cd ~/dotfiles && \
    chmod +x ./install && \
    ./install

# Return to root for SSHD
USER root

# Expose SSH port
EXPOSE 22

# Start SSHD by default
CMD ["/usr/sbin/sshd", "-D"]
