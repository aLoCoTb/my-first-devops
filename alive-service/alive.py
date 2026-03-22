import syslog
import time

def main():
    while True:
        syslog.syslog("I am alive")
        time.sleep(10)

if __name__ == "__main__":
    main()
