import React from "react";
import _ from "lodash";

import ReviewForm from "./ReviewForm";

import {ProjectContext} from "./constants";
import {mercator} from "../utils/mercator";

export default class ReviewChanges extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            acceptTOS: false
        };
    }

    /// API Functions

    createProject = () => {
        if (!this.state.acceptTOS) {
            alert("You must accept the terms of service to continue.");
        } else if (confirm("Do you really want to create this project?")) {
            this.context.processModal(
                "Creating Project",
                () => fetch(
                    "/create-project",
                    {
                        method: "POST",
                        headers: {
                            "Accept": "application/json",
                            "Content-Type": "application/json; charset=utf-8"
                        },
                        body: JSON.stringify({
                            institutionId: this.context.institutionId,
                            projectTemplate: this.context.templateProjectId,
                            useTemplatePlots: this.context.useTemplatePlots,
                            useTemplateWidgets: this.context.useTemplateWidgets,
                            ...this.buildProjectObject()
                        })
                    }
                )
                    .then(response => Promise.all([response.ok, response.json()]))
                    .then(data => {
                        if (data[0] && Number.isInteger(data[1].projectId)) {
                            window.location = `/review-project?projectId=${data[1].projectId}`;
                            return Promise.resolve();
                        } else {
                            return Promise.reject(data[1]);
                        }
                    })
                    .catch(message => {
                        alert("Error creating project:\n" + message);
                    })
            );
        }
    };

    updateProject = () => {
        // TODO: Match project details in context as in state (i.e. do not spread into context).
        const updateSurvey = this.surveyQuestionUpdated(this.context, this.context.originalProject);
        const extraMessage = this.plotsUpdated(this.context, this.context.originalProject)
            ? "  Plots and samples will be recreated, losing all collection data."
            : this.samplesUpdated(this.context, this.context.originalProject)
                ? "  Samples will be recreated, losing all collection data."
                : updateSurvey
                    ? "  Updating survey questions or rules will reset all collected data."
                    : this.allowDrawnSamplesDisallowed(this.context, this.context.originalProject)
                        ? "  Disallowing users to draw samples will reset all collected data."
                        : "";
        if (confirm("Do you really want to update this project?" + extraMessage)) {
            this.context.processModal(
                "Updating Project",
                () => fetch(
                    "/update-project",
                    {
                        method: "POST",
                        headers: {
                            "Accept": "application/json",
                            "Content-Type": "application/json; charset=utf-8"
                        },
                        body: JSON.stringify({
                            projectId: this.context.projectId,
                            ...this.buildProjectObject(),
                            updateSurvey // FIXME this is a shim for when stored questions are in an old format.
                        })
                    }
                )
                    .then(response => Promise.all([response.ok, response.json()]))
                    .then(data => {
                        if (data[0] && data[1] === "") {
                            this.context.setContextState({designMode: "manage"});
                            alert("Project successfully updated!");
                            return Promise.resolve();
                        } else {
                            return Promise.reject(data[1]);
                        }
                    })
                    .catch(message => {
                        alert("Error updating project:\n" + message);
                    })
            );
        }
    };

    /// Helper Functions

    buildProjectObject = () => {
        // TODO pass boundary instead of lon / lat.  Boundary will be arbitrary.
        const boundaryExtent = mercator.parseGeoJson(this.context.boundary, false).getExtent();
        return {
            imageryId: this.context.imageryId,
            projectImageryList: this.context.projectImageryList,
            lonMin: boundaryExtent[0],
            latMin: boundaryExtent[1],
            lonMax: boundaryExtent[2],
            latMax: boundaryExtent[3],
            description: this.context.description,
            name: this.context.name,
            privacyLevel: this.context.privacyLevel,
            projectOptions: this.context.projectOptions,
            designSettings: this.context.designSettings,
            numPlots: this.context.numPlots,
            plotDistribution: this.context.plotDistribution,
            plotShape: this.context.plotShape,
            plotSize: this.context.plotSize,
            plotSpacing: this.context.plotSpacing,
            sampleDistribution: this.context.sampleDistribution,
            samplesPerPlot: this.context.samplesPerPlot,
            sampleResolution: this.context.sampleResolution,
            allowDrawnSamples: this.context.allowDrawnSamples,
            surveyQuestions: this.context.surveyQuestions,
            surveyRules: this.context.surveyRules,
            plotFileName: this.context.plotFileName,
            plotFileBase64: this.context.plotFileBase64,
            sampleFileName: this.context.sampleFileName,
            sampleFileBase64: this.context.sampleFileBase64
        };
    };

    allowDrawnSamplesDisallowed = (projectDetails, originalProject) =>
        originalProject.allowDrawnSamples && !projectDetails.allowDrawnSamples;

    surveyQuestionUpdated = (projectDetails, originalProject) =>
        !_.isEqual(projectDetails.surveyQuestions, originalProject.surveyQuestions)
            || !_.isEqual(projectDetails.surveyRules, originalProject.surveyRules);

    plotsUpdated = (projectDetails, originalProject) =>
        projectDetails.plotDistribution !== originalProject.plotDistribution
            || (["csv", "shp"].includes(this.context.plotDistribution)
                ? projectDetails.plotFileBase64
                : projectDetails.boundary !== originalProject.boundary
                    || projectDetails.numPlots !== originalProject.numPlots
                    || projectDetails.plotShape !== originalProject.plotShape
                    || projectDetails.plotSize !== originalProject.plotSize
                    || projectDetails.plotSpacing !== originalProject.plotSpacing);

    samplesUpdated = (projectDetails, originalProject) =>
        projectDetails.sampleDistribution !== originalProject.sampleDistribution
            || (["csv", "shp"].includes(this.context.sampleDistribution)
                ? projectDetails.sampleFileBase64
                : projectDetails.samplesPerPlot !== originalProject.samplesPerPlot
                    || projectDetails.sampleResolution !== originalProject.sampleResolution);

    /// Render Functions

    renderButtons = () => (
        <div className="d-flex flex-column">
            {this.context.projectId > 0
                ? (
                    <>
                        <input
                            className="btn btn-outline-lightgreen btn-sm col-6 mb-3"
                            onClick={this.updateProject}
                            type="button"
                            value="Update Project"
                        />
                        <input
                            className="btn btn-outline-red btn-sm col-6 mb-3"
                            onClick={() => this.context.setContextState({designMode: "manage"})}
                            type="button"
                            value="Discard Changes"
                        />
                    </>
                ) : (
                    <>
                        <div className="form-check mb-3">
                            <input
                                checked={this.state.acceptTOS}
                                className="form-check-input"
                                id="tos-check"
                                onChange={() => this.setState({acceptTOS: !this.state.acceptTOS})}
                                type="checkbox"
                            />
                            <label className="form-check-label" htmlFor="tos-check">
                            I agree to the <a href="/terms" target="_blank">Terms of Service</a>.
                            </label>
                        </div>
                        <input
                            className="btn btn-outline-lightgreen btn-sm col-6"
                            onClick={this.createProject}
                            type="button"
                            value="Create Project"
                        />
                    </>
                )}
            <input
                className="btn btn-outline-lightgreen btn-sm col-6"
                onClick={() => this.context.setContextState({designMode: "wizard"})}
                type="button"
                value="Continue Editing"
            />
        </div>
    );

    render() {
        return (
            <div
                className="d-flex flex-column full-height align-items-center p-3"
                id="changes"
            >
                <div
                    style={{
                        display: "flex",
                        height: "100%",
                        justifyContent: "center",
                        width: "100%",
                        overflow: "auto"
                    }}
                >
                    <div
                        className="col-7 px-0 mr-2 overflow-auto bg-lightgray"
                        style={{border: "1px solid black", borderRadius: "6px"}}
                    >
                        <h2 className="bg-lightgreen w-100 py-1">Project Details</h2>
                        <div className="px-3 pb-3">
                            <ReviewForm/>
                        </div>
                    </div>
                    <div
                        className="col-4 px-0 mr-2 overflow-auto bg-lightgray"
                        style={{border: "1px solid black", borderRadius: "6px"}}
                    >
                        <h2 className="bg-lightgreen w-100 py-1">Project Management</h2>
                        <div className="p-3">
                            {this.renderButtons()}
                        </div>
                    </div>
                </div>
            </div>
        );
    }
}
ReviewChanges.contextType = ProjectContext;
