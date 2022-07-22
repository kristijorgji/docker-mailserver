mail_sender ()
{
domain=kristijorgji.com
from="test@test.com"
to="me@kristijorgji.com"
subject="Test $(date +'%F_%H_%M_%S')"
message="A nice test"

{
    sleep 1
    echo "helo $domain"
    sleep 0.5
    echo "mail from:<$from>"
    sleep 0.5
    echo "rcpt to:<$to>"
    echo
    echo "data"
    sleep 0.5
    echo "ddd"
    echo "mmm"
} | telnet localhost 25 |
    grep -q "Unknown user" &&
    echo "Invalid email" ||
    echo "Valid email"
}

mail_sender
