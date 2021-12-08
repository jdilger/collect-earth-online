import React from "react";

import {capitalizeFirst} from "../utils/generalUtils";
import {ProjectContext} from "./constants";

export function Overview(props) {
    return (
        <ProjectContext.Consumer>
            {({
                name,
                description,
                privacyLevel,
                setProjectDetails,
                projectOptions,
                projectOptions: {showGEEScript, showPlotInformation, collectConfidence, autoLaunchGeoDash},
                projectId
            }) => (
                <div id="project-info">
                    {projectId < 0 && <ProjectTemplateSelection {...props}/>}
                    <div className="form-group">
                        <h3 htmlFor="project-name">Name</h3>
                        <input
                            className="form-control form-control-sm"
                            id="project-name"
                            maxLength="200"
                            onChange={e => setProjectDetails({name: e.target.value})}
                            type="text"
                            value={name}
                        />
                    </div>
                    <div className="form-group">
                        <h3 htmlFor="project-description">Description</h3>
                        <textarea
                            className="form-control form-control-sm"
                            id="project-description"
                            maxLength="2000"
                            onChange={e => setProjectDetails({description: e.target.value})}
                            value={description}
                        />
                    </div>
                    <h3>Visibility</h3>
                    <div className="mb-3" id="project-visibility">
                        <div className="form-check form-check-inline">
                            <input
                                checked={privacyLevel === "public"}
                                className="form-check-input"
                                id="privacy-public"
                                onChange={() => setProjectDetails({privacyLevel: "public"})}
                                type="radio"
                            />
                            <label
                                className="form-check-label"
                                htmlFor="privacy-public"
                            >
                                Public: <i>All Users</i>
                            </label>
                        </div>
                        <div className="form-check form-check-inline">
                            <input
                                checked={privacyLevel === "users"}
                                className="form-check-input"
                                id="privacy-users"
                                onChange={() => setProjectDetails({privacyLevel: "users"})}
                                type="radio"
                            />
                            <label className="form-check-label" htmlFor="privacy-users">
                                Users: <i>Logged In Users</i>
                            </label>
                        </div>
                        <div className="form-check form-check-inline">
                            <input
                                checked={privacyLevel === "institution"}
                                className="form-check-input"
                                id="privacy-institution"
                                onChange={() => setProjectDetails({privacyLevel: "institution"})}
                                type="radio"
                            />
                            <label className="form-check-label" htmlFor="privacy-institution">
                                Institution: <i>Group Members</i>
                            </label>
                        </div>
                        <div className="form-check form-check-inline">
                            <input
                                checked={privacyLevel === "private"}
                                className="form-check-input"
                                id="privacy-private"
                                onChange={() => setProjectDetails({privacyLevel: "private"})}
                                type="radio"
                            />
                            <label className="form-check-label" htmlFor="privacy-private">
                                Private: <i>Group Admins</i>
                            </label>
                        </div>
                        <p className="font-italic ml-2 small" id="privacy-level-text">
                            {(privacyLevel === "public" || privacyLevel === "users")
                                && "**Public imagery will be visible to all users, and institution imagery will only be available"
                                    + " to the users in this institution."}
                        </p>
                    </div>
                    <h3>Project Options</h3>
                    <div className="form-check">
                        <input
                            checked={showGEEScript}
                            className="form-check-input"
                            id="showGEEScript"
                            onChange={() => setProjectDetails({
                                projectOptions: {...projectOptions, showGEEScript: !showGEEScript}
                            })}
                            type="checkbox"
                        />
                        <label className="form-check-label" htmlFor="showGEEScript">
                            Show GEE Script Link on Collection Page
                        </label>
                    </div>
                    <div className="form-check">
                        <input
                            checked={showPlotInformation}
                            className="form-check-input"
                            id="showPlotInformation"
                            onChange={() => setProjectDetails({
                                projectOptions: {...projectOptions, showPlotInformation: !showPlotInformation}
                            })}
                            type="checkbox"
                        />
                        <label className="form-check-label" htmlFor="showPlotInformation">
                            Show Extra Plot Columns on Collection Page
                        </label>
                    </div>
                    <div className="form-check">
                        <input
                            checked={collectConfidence}
                            className="form-check-input"
                            id="collectConfidence"
                            onChange={() => setProjectDetails({
                                projectOptions: {...projectOptions, collectConfidence: !collectConfidence}
                            })}
                            type="checkbox"
                        />
                        <label className="form-check-label" htmlFor="collectConfidence">
                            Collect Plot Confidence on Collection Page
                        </label>
                    </div>
                    <div className="form-check">
                        <input
                            checked={autoLaunchGeoDash}
                            className="form-check-input"
                            id="autoLaunchGeoDash"
                            onChange={() => setProjectDetails({
                                projectOptions: {...projectOptions, autoLaunchGeoDash: !autoLaunchGeoDash}
                            })}
                            type="checkbox"
                        />
                        <label className="form-check-label" htmlFor="autoLaunchGeoDash">
                            Auto-launch Geo-Dash
                        </label>
                    </div>
                </div>
            )}
        </ProjectContext.Consumer>
    );
}

class ProjectTemplateSelection extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            projectFilter: "",
            selectedTemplateProjectId: this.context.templateProjectId || -1
        };
    }

    render() {
        const {templateProjectId, useTemplateWidgets, useTemplatePlots, setProjectDetails} = this.context;
        const {setProjectTemplate, clearTemplateSelection, templateProjectList} = this.props;
        return (
            <div id="project-template-selector">
                <div className="d-flex align-items-end justify-content-between">
                    <div className="form-group">
                        <h3 htmlFor="project-filter">Template Filter (Name or ID)</h3>
                        <input
                            className="form-control form-control-sm"
                            id="project-filter"
                            onChange={e => this.setState({projectFilter: e.target.value})}
                            type="text"
                            value={this.state.projectFilter}
                        />
                    </div>
                    <div className="form-group mx-3" style={{flex: "1 1 1px"}}>
                        <h3 htmlFor="project-template">Select Template</h3>
                        <select
                            className="form-control-sm form-control"
                            id="project-template"
                            onChange={e => this.setState({
                                selectedTemplateProjectId: parseInt(e.target.value)
                            })}
                            size="1"
                            style={{height: "calc(1.5em + .5rem + 2px)"}}
                            value={this.state.selectedTemplateProjectId}
                        >
                            {templateProjectList
                                && templateProjectList[0].id > 0
                                && <option key={-1} value={-1}>- Select Project -</option>}
                            {templateProjectList && templateProjectList
                                .filter(proj => (proj.id + proj.name.toLocaleLowerCase())
                                    .includes(this.state.projectFilter.toLocaleLowerCase()))
                                .map(proj => <option key={proj.id} value={proj.id}>{proj.id} - {proj.name}</option>)}
                        </select>
                    </div>
                    <span className="form-group">
                        <input
                            className="btn btn-lightgreen mr-1"
                            disabled={this.state.selectedTemplateProjectId === -1}
                            onClick={() => setProjectTemplate(this.state.selectedTemplateProjectId)}
                            style={{height: "calc(1.5em + .5rem + 2px)", padding: "0 .5rem"}}
                            type="button"
                            value="Load"
                        />
                        <input
                            className="btn btn-lightgreen"
                            onClick={() => {
                                this.setState({selectedTemplateProjectId: -1});
                                clearTemplateSelection();
                            }}
                            style={{height: "calc(1.5em + .5rem + 2px)", padding: "0 .5rem"}}
                            type="button"
                            value="Clear"
                        />
                    </span>
                </div>
                {templateProjectId > 0 && (
                    <div className="pb-2">
                        <h3 className="mb-1">Copy Options</h3>
                        <div className="d-flex">
                            <div className="form-check form-check-inline">
                                <input
                                    checked={useTemplatePlots}
                                    className="form-check-input"
                                    id="use-template-plots"
                                    onChange={this.props.toggleTemplatePlots}
                                    type="checkbox"
                                />
                                <label
                                    className="form-check-label"
                                    htmlFor="use-template-plots"
                                >
                                    Copy Template Plots and Samples
                                </label>
                            </div>
                            <div className="form-check form-check-inline mt-1">
                                <input
                                    checked={useTemplateWidgets}
                                    className="form-check-input"
                                    id="use-template-widgets"
                                    onChange={() => setProjectDetails({useTemplateWidgets: !useTemplateWidgets})}
                                    type="checkbox"
                                />
                                <label
                                    className="form-check-label"
                                    htmlFor="use-template-widgets"
                                >
                                    Copy Template Widgets
                                </label>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        );
    }
}
ProjectTemplateSelection.contextType = ProjectContext;

export function OverviewReview() {
    return (
        <ProjectContext.Consumer>
            {({name, description, privacyLevel, projectOptions}) => (
                <div className="d-flex flex-column">
                    <label><b>Name:</b> {name}</label>
                    <label><b>Description:</b> {description}</label>
                    <label><b>Visibility:</b> {capitalizeFirst(privacyLevel)}</label>
                    <label className="font-weight-bold">Project Options:</label>
                    <ul>
                        <li>
                            <b>{projectOptions.showGEEScript ? "Show " : "Don't Show "}</b>
                            GEE Script Link on Collection Page
                        </li>
                        <li>
                            <b>{projectOptions.showPlotInformation ? "Show " : "Don't Show "}</b>
                            Extra Plot Columns on Collection Page
                        </li>
                        <li>
                            <b>{projectOptions.collectConfidence ? "Collect " : "Don't Collect "}</b>
                            Plot Confidence
                        </li>
                        <li>
                            <b>{projectOptions.autoLaunchGeoDash ? "Auto-launch " : "Don't Auto-launch "}</b>
                            Geo-Dash Window
                        </li>
                    </ul>
                </div>
            )}
        </ProjectContext.Consumer>
    );
}

export function OverviewIntro() {
    return (
        <div className="p-3">
            <h3 className="mb-3">Welcome to the project creation widget!</h3>
            <label>
                You can use the Back and Next buttons below or the circles above each of the six
                 project creation steps at the top of this page to navigate between stages of the wizard.
            </label>
        </div>
    );
}
