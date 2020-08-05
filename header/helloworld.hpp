#include <string>

class Hello{
private:
	std::string name;
public:
	Hello(std::string);
	virtual void display();
};