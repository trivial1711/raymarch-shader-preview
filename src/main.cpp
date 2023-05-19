#include <iostream>
#include <SFML/Window.hpp>
#include <SFML/Graphics.hpp>
#include "../include/cxxopts.hpp"
#include <cmath>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <chrono>

using namespace std;

const int NUM_CONTROLS = 12;
const string CONTROLS_STRINGS[2 * NUM_CONTROLS] = {
    "Left click:", "Lock mouse",
    "Esc:", "Release mouse",
    "Mouse:", "Look",
    "W:", "Move forward",
    "A:", "Move left",
    "S:", "Move backward",
    "D:", "Move right",
    "Q:", "Move down",
    "E:", "Move up",
    "F12:", "Take screenshot",
    "Tab:", "Toggle controls display",
    "F:", "Toggle frame rate display"
};
const float MARGIN_PIXELS = 8.f;
const int FONT_SIZE = 16;
const float OUTLINE_THICKNESS = 2.f;

int main(int ac, char** av)
{
    cxxopts::Options options("Shader test", "Test a GLSL raymarching shader. The shader should implement a function "
        "vec3 rayColor(vec3 position, vec3 direction). Use \"time\" in the shader to get the time in seconds.");
    options.add_options()
        ("h,help", "print usage")
        ("H,width", "width of window (in pixels)", cxxopts::value<int>()->default_value("1280"))
        ("W,height", "height of window (in pixels)", cxxopts::value<int>()->default_value("720"))
        ("f,frame-rate", "frame rate limit (in frames per second)", cxxopts::value<int>()->default_value("240"))
        ("v,fov", "field of view (in degrees)", cxxopts::value<float>()->default_value("75") )
        ("s,speed", "speed of camera (in units per second)", cxxopts::value<float>()->default_value("1.5"))
        ("S,sensitivity", "mouse sensitivity", cxxopts::value<float>()->default_value("1.3"))
        ("in", "input file name (glsl)", cxxopts::value<string>())
        ("F,font", "font file name", cxxopts::value<string>()->default_value("NotoSans-Regular.ttf"))
    ;
    options.parse_positional({"in"});
    auto result = options.parse(ac, av);

    if (result.count("help")) {
        cout << options.help() << endl;
        return 0;
    }
    if (!result.count("in")) {
        cerr << "No input file specified. Try running the program again with the --help option." << endl;
        return 1;
    }

    int width = result["width"].as<int>();
    int height = result["height"].as<int>();
    int frameRate = result["frame-rate"].as<int>();
    float fov = result["fov"].as<float>();
    float speed = result["speed"].as<float>();
    float sensitivity = result["sensitivity"].as<float>();
    
    sf::Shader shader;

    if(!sf::Shader::isAvailable()) {
        cerr << "System does not support shaders" << endl;
        return 1;
    }

    ifstream file(result["in"].as<string>());
    if(file) {
        string contents {
            std::istreambuf_iterator<char>(file),
            std::istreambuf_iterator<char>()
        };

        string shaderSource =
            "#version 130\n"
            "layout(origin_upper_left) in vec4 gl_FragCoord;\n"
            "uniform vec3 position;\n"
            "uniform mat4 fragCoordToRayDir;\n"
            "uniform float time;\n"
            + contents + "\n"
            "void main() { gl_FragColor = vec4(rayColor(position, normalize((fragCoordToRayDir * gl_FragCoord).xyz)), 1.0 + min(time, 0.0)); }\n";

        if(!shader.loadFromMemory(shaderSource, sf::Shader::Fragment)) {
            cerr << "Failed to load shader from " << result["in"].as<string>() << endl;
            return 1;
        }
    } else {
        cerr << "File " << result["in"].as<string>() << " does not exist";
        return 1;
    }

    sf::Font font;
    if(!font.loadFromFile(result["font"].as<string>() )) {
        cerr << "Font file not found: " << result["font"].as<string>() << endl;
    }

    sf::Text controlsText[2 * NUM_CONTROLS];
    float maxWidth = 0.f;
    float maxHeight = 0.f;
    for(int i = 0; i < 2 * NUM_CONTROLS; i++) {
        controlsText[i].setString(CONTROLS_STRINGS[i]);
        controlsText[i].setFont(font);
        controlsText[i].setCharacterSize(FONT_SIZE);
        controlsText[i].setOutlineThickness(OUTLINE_THICKNESS);
        if(i % 2 == 0) {
            maxWidth = max(maxWidth, controlsText[i].getLocalBounds().width);
            maxHeight = max(maxHeight, controlsText[i].getLocalBounds().height);
        }
    }

    for(int i = 0; i < 2 * NUM_CONTROLS; i++) {
        const float y = maxHeight * (i / 2) + MARGIN_PIXELS;
        const float x = (i % 2 == 0) ? MARGIN_PIXELS + maxWidth - controlsText[i].getLocalBounds().width : 2 * MARGIN_PIXELS + maxWidth;
        controlsText[i].setPosition({x, y});
    }

    sf::Text frameRateText;
    frameRateText.setFont(font);
    frameRateText.setCharacterSize(FONT_SIZE);
    frameRateText.setOutlineThickness(OUTLINE_THICKNESS);

    bool bMouseLock = false;
    bool bFrameRateDisplay = false;
    bool bControlsDisplay = true;

    sf::RenderWindow window(sf::VideoMode(width, height),
        "Shader test", sf::Style::Default);
    window.setFramerateLimit(frameRate);
    window.setKeyRepeatEnabled(false);
    sf::Mouse::setPosition({width / 2, height / 2}, window);

    sf::Vector3f position {};
    sf::Vector2f angle {}; // in spherical coordinates

    sf::Clock frameClock;
    sf::Clock programClock;

    while (window.isOpen())
    {
        bool bShouldCaptureScreenThisFrame = false;
        sf::Event event;
        while (window.pollEvent(event))
        {
            if (event.type == sf::Event::Closed)
            {
                window.close();
                return 0;
            }
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::Escape
                || event.type == sf::Event::LostFocus) {
                bMouseLock = false;
            }
            if (event.type == sf::Event::MouseButtonPressed && event.mouseButton.button == sf::Mouse::Left) {
                bMouseLock = true;
            }
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::Tab) {
                bControlsDisplay ^= 1;
            }
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::F) {
                bFrameRateDisplay ^= 1;
            }
            if (event.type == sf::Event::Resized) {
                sf::FloatRect visibleArea(0, 0, event.size.width, event.size.height);
                window.setView(sf::View(visibleArea));
            }
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::F12) {
                bShouldCaptureScreenThisFrame = true;
            }
        }
        window.clear();

        float deltaTime = frameClock.restart().asSeconds();
        
        window.setMouseCursorVisible(!bMouseLock);
        
        if(bMouseLock) { 
            const sf::Vector2i center = {(int)window.getSize().x / 2, (int)window.getSize().y / 2};
            sf::Vector2i displacement = sf::Mouse::getPosition(window) - center;
            sf::Vector2f angularDisplacement = {sensitivity * displacement.x / width, sensitivity * displacement.y / width};

            angle.x -= angularDisplacement.x;
            angle.x -= round(angle.x / (2 * numbers::pi)) * 2 * numbers::pi;
            angle.y = clamp(-angularDisplacement.y + angle.y, -(float)numbers::pi / 2, (float)numbers::pi / 2);

            sf::Mouse::setPosition(center, window);
        }

        const sf::Vector3f forwardVector = {cos(angle.y) * cos(angle.x), cos(angle.y) * sin(angle.x), sin(angle.y)};
        const sf::Vector3f leftVector = {-sin(angle.x), cos(angle.x), 0.f};
        const sf::Vector3f upVector = {0.f, 0.f, 1.f};
        const sf::Vector3f cameraUpVector = {-sin(angle.y) * cos(angle.x), - sin(angle.y) * sin(angle.x), cos(angle.y)};
        const float adjustmentPerPixel = 2 * tan(fov / 360.f * numbers::pi) / (window.getSize().x);
        const sf::Vector3f topLeftRay = forwardVector + adjustmentPerPixel *
            (leftVector * (window.getSize().x / 2.f) + cameraUpVector * (window.getSize().y / 2.f));

        const float fragCoordToRayDir[16] = {
            -adjustmentPerPixel * leftVector.x, -adjustmentPerPixel * leftVector.y, -adjustmentPerPixel * leftVector.z, 0,
            -adjustmentPerPixel * cameraUpVector.x, -adjustmentPerPixel * cameraUpVector.y, -adjustmentPerPixel * cameraUpVector.z, 0,
            0, 0, 0, 0,
            topLeftRay.x, topLeftRay.y, topLeftRay.z, 1
        };


        position += deltaTime * speed * (sf::Keyboard::isKeyPressed(sf::Keyboard::W) - sf::Keyboard::isKeyPressed(sf::Keyboard::S)) * forwardVector;
        position += deltaTime * speed * (sf::Keyboard::isKeyPressed(sf::Keyboard::A) - sf::Keyboard::isKeyPressed(sf::Keyboard::D)) * leftVector;
        position += deltaTime * speed * (sf::Keyboard::isKeyPressed(sf::Keyboard::E) - sf::Keyboard::isKeyPressed(sf::Keyboard::Q)) * upVector;

        sf::RectangleShape fullscreenShape;
        fullscreenShape.setSize({(float)window.getSize().x, (float)window.getSize().y});
        fullscreenShape.setPosition(0, 0);

        shader.setUniform("position", position);
        shader.setUniform("fragCoordToRayDir", sf::Glsl::Mat4(fragCoordToRayDir));
        shader.setUniform("time", programClock.getElapsedTime().asSeconds());
        window.draw(fullscreenShape, &shader);

        if(bShouldCaptureScreenThisFrame) {
            sf::Texture texture;
            texture.create(window.getSize().x, window.getSize().y);
            texture.update(window);

            auto now = chrono::system_clock::now();
            auto in_time_t = chrono::system_clock::to_time_t(now);
            stringstream datetime;
            datetime << std::put_time(std::localtime(&in_time_t), "%Y-%m-%d-%H-%M-%S");
            string filename = datetime.str() + ".png";
            if (texture.copyToImage().saveToFile(filename))
            {
                cout << "Screenshot saved to " << filename << std::endl;
            }
        }

        if(bControlsDisplay) {
            for(sf::Text& text : controlsText) {
                window.draw(text);
            }
        }

        if(bFrameRateDisplay) {
            stringstream stream;
            stream << std::fixed << std::setprecision(1) << 1 / deltaTime;
            stream << " FPS";
            frameRateText.setString(stream.str());
            frameRateText.setPosition({MARGIN_PIXELS, (float)window.getSize().y - frameRateText.getLocalBounds().height - MARGIN_PIXELS});

            window.draw(frameRateText);
        }

        window.display();
    }

    return 0;
}