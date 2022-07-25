mail_sender ()
{
domain=kristijorgji.com
from="test@test.com"
to="me@kristijorgji.com"
now=$(date +'%F_%H_%M_%S')
subject="Test $now"
message="A nice test $now"

{
    sleep 1
    echo "helo $domain"
    sleep 0.5
    echo "mail from:<$from>"
    sleep 0.5
    echo "rcpt to:<$to>"
    sleep 0.5
    echo -e "data\nsubject: $subject\n$message\r\n."
} | telnet localhost 25 |
    grep -q "Unknown user" &&
    echo "Invalid email" ||
    echo "Valid email"
}

mail_sender
