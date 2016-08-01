//
//  main.cpp
//  iOSAVRateServer
//
//  Created by Pierre on 16/03/13.
//  Copyright (c) 2013 T-Labs. All rights reserved.
//

#include <iostream>
#include "NetworkStream.h"


void sendSlider(NetworkStream &stream) {


	stream.write("<?xml version=\"1.0\" encoding=\"iso-8859-1\"?>");
	stream.write("<root>"); 
	stream.write("<playondevice>true</playondevice>");
	stream.write("<slider>");
	stream.write("<name>Quality</name>");
	stream.write("<label></label>");
	stream.write("<label>lowest</label>");
	stream.write("<label></label>");
	stream.write("<label>low</label>");
	stream.write("<label></label>");
	stream.write("<label>medium</label>");
	stream.write("<label></label>");
	stream.write("<label>high</label>");
	stream.write("<label></label>");
	stream.write("<label>highest</label>");
	stream.write("<label></label>");
	stream.write("<min>0</min>");
	stream.write("<max>10</max>");
	stream.write("<ticks>0</ticks>");
	stream.write("<fixed>true</fixed>");
	stream.write("<shownumbers>true</shownumbers>");
	stream.write("</slider>");
/*
	stream.write("<slider>");
	stream.write("<name>Comfort</name>");
	stream.write("<label></label>");
	stream.write("<label>lowest</label>");
	stream.write("<label></label>");
	stream.write("<label>low</label>");
	stream.write("<label></label>");
	stream.write("<label>medium</label>");
	stream.write("<label></label>");
	stream.write("<label>high</label>");
	stream.write("<label></label>");
	stream.write("<label>highest</label>");
	stream.write("<label></label>");
	stream.write("<min>0</min>");
	stream.write("<max>10</max>");
	stream.write("<ticks>0</ticks>");
	stream.write("<fixed>true</fixed>");
	stream.write("<shownumbers>true</shownumbers>");
	stream.write("</slider>");
*/
	stream.write("<buttons>");
	stream.write("<name>Acceptance</name>");
	stream.write("<label>Yes</label>");
	stream.write("<label>No</label>");
	stream.write("</buttons>"); 
/*
	stream.write("<buttons>");
	stream.write("<name>Depth2</name>");
	stream.write("<label>Very low</label>");
	stream.write("<label>Medium</label>");
	stream.write("<label>low</label>");
	stream.write("<label>Strong</label>");
	stream.write("<label>Very strong</label>");
	stream.write("</buttons>"); */
	stream.write("</root>");

}

void serverScript();
void standaloneClientScript();

int main(int argc, const char * argv[]) {


	standaloneClientScript();

    return 0;
}


void standaloneClientScript() {
	NetworkStream client("127.0.0.1", 8080);

	
	std::string line;
	client.read(line);

	client.write("[ASKPLAYLIST]");


	client.read(line);
  	if(line == "[NOPLAYLIST]") {
		std::cout << "[NOPLAYLIST]\n";
	} else {
		std::string nextLine;
		std::string buffer, tmp;
		line = "";
		bool done = false;
		while(!done && client.read(tmp) > 0) {
			buffer += tmp;
			if(buffer.size() > 17) {
				int pos = buffer.find("[");
				while(pos >= 0) {
					if(pos >= 0 && buffer.length()-pos >= 17) {
						std::string tag = buffer.substr(pos, 17);
						if(tag == "[END_ONEPLAYLIST]") {
							std::cout << "one playlist: ";
							nextLine = buffer.substr(pos+17,buffer.length()-pos-17);

							if(pos >0)
								line += buffer.substr(0, pos-1);
							else
								line += buffer;

							std::cout << line << "\n";
							line = "";
						} 

						if(pos >= 0 && buffer.length()-pos >= 18) {
							std::string tag = buffer.substr(pos, 18);
							if(tag == "[END_NEWPLAYLISTS]") {
								nextLine = buffer.substr(pos+18,buffer.length()-pos-18);
								std::cout << "That's all folks!\n";
								done = true;
							}
						}
					}
					buffer = nextLine;
					pos = nextLine.find("[");
				} 
			} 
		}
		

		std::cout << line << "\n";

	}

	client.write("[CLOSE]");

}


void serverScript() {
	std::cout << "Make new server\n";
	bool playOnDevice = true;
	NetworkStream server(8080);

	sendSlider(server);

	for(int i = 0 ; i < 3 ; ++i) {
		std::string line;

		if(!playOnDevice) {
			server.read(line);

			if(line == "[PLAY]") {
				std::cout << "[PLAY]" << std::endl;
				server.write("[RELEASEGUI]");
			}

		} else {
			server.read(line);

			if(line == "[NEXT2PLAY]") {
				std::cout << "[NEXT2PLAY]" << std::endl;

				server.write("http://video.blendertestbuilds.de/download.blender.org/peach/trailer_iphone.m4v");

			}

		}

		server.read(line);
		std::cout << "should be scores: " << line << std::endl;

		if(i < 2)
			server.write("[CONTINUE]", 11);
	}

	server.write("[DONE]", 7);

}



