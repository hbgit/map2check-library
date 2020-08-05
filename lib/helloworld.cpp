#include <iostream>
#include "../header/helloworld.hpp"

using namespace std;

Hello::Hello(string name):name(name){}

void Hello::display(){
	cout << "Hello: " << this->name << endl;
}