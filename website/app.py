# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import datetime

from flask import Flask, redirect, request, render_template

from views.errors import errors_bp

app = Flask(__name__)
app.register_blueprint(errors_bp)

# TODO(anassri, engelke): use API call instead of this
# (This is based on the API design doc for now.)

SAMPLE_CAMPAIGNS = [
    {
        "id": "aaaa-bbbb-cccc-dddd",
        "name": "cash for camels",
        "image_url": "https://images.pexels.com/photos/2080195/pexels-photo-2080195.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260",
        "goal": 2500,
        "managers": ["Chris the camel", "Carissa the camel"],
        "description": "The camels need money.",
        "updated": datetime.date(2021, 2, 1),
    },
    {
        "id": "eeee-ffff-gggg-hhhh",
        "name": "water for fish",
        "image_url": "https://images.pexels.com/photos/2156311/pexels-photo-2156311.jpeg?auto=compress&cs=tinysrgb&dpr=2&h=750&w=1260",
        "goal": 2500,
        "managers": [
            "Fred the fish",
        ],
        "description": "Help us keep all the fish hydrated!",
        "updated": datetime.date(2021, 5, 10),
    },
]


@app.route("/")
def webapp_list_campaigns():
    return render_template("home.html", campaigns=SAMPLE_CAMPAIGNS)


@app.route("/createCampaign", methods=["GET"])
def webapp_create_campaign_get():
    return render_template("create-campaign.html")


@app.route("/createCampaign", methods=["POST"])
def webapp_create_campaign_post():
    # TODO: do something with the collected data
    print("Name: ", request.form["name"])
    print("Goal: ", request.form["goal"])
    print("Managers: ", request.form["managers"])

    return redirect("/")


@app.route("/viewCampaign")
def webapp_view_campaign():
    campaign_id = request.args["campaign_id"]
    campaign_instance = [
        campaign for campaign in SAMPLE_CAMPAIGNS if campaign["id"] == campaign_id
    ][0]
    return render_template("view-campaign.html", campaign=campaign_instance)

app.run()