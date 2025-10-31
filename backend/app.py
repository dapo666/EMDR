from flask import Flask, request, jsonify, send_from_directory, session
from flask_cors import CORS
import os

app = Flask(__name__, static_folder="../frontend/dist")
app.secret_key = os.environ.get("SESSION_SECRET", "supersecretkey")
import uuid
CORS(app)

def get_session_id():
    # First try to get session from URL query parameter
    session_id_from_url = request.args.get('session')
    if session_id_from_url:
        return session_id_from_url
    
    # Fall back to cookie-based session
    if "session_id" not in session:
        session["session_id"] = str(uuid.uuid4())
    return session["session_id"]

session_states = {}

def get_default_state():
    return {
        "ball_state": {
            "speed": 5,
            "bounceMode": "horizontal",
            "isMoving": False,
            "ballSize": 30
        },
        "background_state": {
            "backgroundColor": "#ffffff"
        },
        "ball_color_state": {
            "ballColor": "#2196f3",
            "randomColor": False
        }
        ,
        "sound_state": {
            "bilateral": False,
            "speed": 500
        }
    }
@app.route("/api/sound", methods=["GET"])
def get_sound_state():
    state = get_session_state()
    return jsonify(state["sound_state"])

@app.route("/api/sound", methods=["POST"])
def set_sound_state():
    data = request.json
    state = get_session_state()
    state["sound_state"]["bilateral"] = data.get("bilateral", state["sound_state"]["bilateral"])
    state["sound_state"]["speed"] = data.get("speed", state["sound_state"]["speed"])
    return jsonify(state["sound_state"])

def get_session_state():
    session_id = get_session_id()
    # Limit to 50 simultaneous sessions
    if session_id not in session_states:
        if len(session_states) >= 50:
            return jsonify({
                "error": True,
                "message": "Max session limit reached for free version. To allow new connection please subscribe to paid version. You can contact us by email: info@expatpsychologie.nl"
            }), 429
        session_states[session_id] = get_default_state()
    return session_states[session_id]
@app.route("/api/background", methods=["GET"])
def get_background():
    state = get_session_state()
    return jsonify(state["background_state"])

@app.route("/api/background", methods=["POST"])
def set_background():
    data = request.json
    state = get_session_state()
    state["background_state"]["backgroundColor"] = data.get("backgroundColor", state["background_state"]["backgroundColor"])
    return jsonify(state["background_state"])

@app.route("/api/ballcolor", methods=["GET"])
def get_ballcolor():
    state = get_session_state()
    return jsonify(state["ball_color_state"])

@app.route("/api/ballcolor", methods=["POST"])
def set_ballcolor():
    data = request.json
    state = get_session_state()
    if "ballColor" in data:
        state["ball_color_state"]["ballColor"] = data["ballColor"]
    if "randomColor" in data:
        state["ball_color_state"]["randomColor"] = data["randomColor"]
    return jsonify(state["ball_color_state"])

@app.route("/api/session-count", methods=["GET"])
def get_session_count():
    return jsonify({
        "count": len(session_states),
        "limit": 50,
        "limitReached": len(session_states) >= 50
    })

@app.route("/api/ball", methods=["GET"])
def get_ball():
    state = get_session_state()
    return jsonify(state["ball_state"])

@app.route("/api/ball", methods=["POST"])
def set_ball():
    data = request.json
    state = get_session_state()
    state["ball_state"]["speed"] = data.get("speed", state["ball_state"]["speed"])
    state["ball_state"]["bounceMode"] = data.get("bounceMode", state["ball_state"]["bounceMode"])
    state["ball_state"]["isMoving"] = data.get("isMoving", state["ball_state"]["isMoving"])
    state["ball_state"]["ballSize"] = data.get("ballSize", state["ball_state"]["ballSize"])
    return jsonify(state["ball_state"])

@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def serve_vue(path):
    if path.startswith('api/'):
        return 'Not Found', 404
    file_path = os.path.join(app.static_folder, path)
    if path != "" and os.path.exists(file_path):
        return send_from_directory(app.static_folder, path)
    else:
        return send_from_directory(app.static_folder, "index.html")

if __name__ == "__main__":
    app.run(debug=True)
