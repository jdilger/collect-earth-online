import React from "react";
import ReactDOM from "react-dom";
import { mercator, ceoMapStyles } from "../js/mercator-openlayers.js";

class Home extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            projects: [],
            showHideSideBar:"col-lg-9 col-md-12 pl-0",
            showHideLpanel:"col-lg-3 pr-0 pl-0"
        };
        this.toggleSidebar=this.toggleSidebar.bind(this);

    }

    componentDidMount() {
        // Fetch projects
        fetch(this.props.documentRoot + "/get-all-projects?userId=" + this.props.userId)
            .then(response => response.json())
            .then(data => this.setState({projects: data}));
    }

    toggleSidebar() {
        let sidebarcss = (this.state.showHideSideBar === "col-lg-9 col-md-12 pl-0 col-xl-12 col-xl-9") ? "col-lg-9 col-md-12 pl-0" : "col-lg-9 col-md-12 pl-0 col-xl-12 col-xl-9";
        document.getElementById("tog-symb").children[0].classList.toggle('fa-caret-left');
        document.getElementById("tog-symb").children[0].classList.toggle('fa-caret-right');
        let lpanelcss = (this.state.showHideLpanel === "col-lg-3 pr-0 pl-0 d-none col-xl-3") ? "col-lg-3 pr-0 pl-0" : "col-lg-3 pr-0 pl-0 d-none col-xl-3";
        this.setState({showHideSideBar: sidebarcss, showHideLpanel: lpanelcss});
    }

    render() {
        return (
            <div id="bcontainer">
                <span id="mobilespan"></span>
                <div className="Wrapper">
                    <div className="row tog-effect">
                        <SideBar documentRoot={this.props.documentRoot}
                                 userName={this.props.userName}
                                 projects={this.state.projects} showHideLpanel={this.state.showHideLpanel}/>
                        <MapPanel documentRoot={this.props.documentRoot}
                                  userId={this.props.userId}
                                  projects={this.state.projects} toggleSidebar={this.toggleSidebar} showHideSideBar={this.state.showHideSideBar} showHideTogSym={this.state.showHideTogSym}/>
                    </div>
                </div>
            </div>
        );
    }
}

class MapPanel extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            imagery: [],
            mapConfig: null,
            clusterExtent: [],
            clickedFeatures: [],
            projectMarkersShown: false,
        };
    }

    componentDidMount() {
        // Fetch imagery
        fetch(this.props.documentRoot + "/get-all-imagery")
            .then(response => response.json())
            .then(data => this.setState({imagery: data}));
    }

    componentDidUpdate() {
        if (this.state.mapConfig == null && this.state.imagery.length > 0) {
            const mapConfig = mercator.createMap("home-map-pane", [0.0, 0.0], 1, this.state.imagery.slice(0,1));
            mercator.setVisibleLayer(mapConfig, this.state.imagery[0].title);
            this.setState({mapConfig: mapConfig});
        }
        if (this.state.mapConfig && this.props.projects.length > 0 && this.state.projectMarkersShown == false) {
            this.addProjectMarkersAndZoom(this.state.mapConfig,
                                          this.props.projects,
                                          this.props.documentRoot,
                                          40); // clusterDistance = 40, use null to disable clustering
        }
    }

    addProjectMarkersAndZoom(mapConfig, projects, documentRoot, clusterDistance) {
        const projectSource = mercator.projectsToVectorSource(projects);
        if (clusterDistance == null) {
            mercator.addVectorLayer(mapConfig,
                                    "projectMarkers",
                                    projectSource,
                                    ceoMapStyles.ceoIcon);
        } else {
            mercator.addVectorLayer(mapConfig,
                                    "projectMarkers",
                                    mercator.makeClusterSource(projectSource, clusterDistance),
                                    feature => mercator.getCircleStyle(10, "#3399cc", "#ffffff", 1, feature.get("features").length, "#ffffff"));
        }
        mercator.addOverlay(mapConfig, "projectPopup", document.getElementById("projectPopUp"));
        const overlay = mercator.getOverlayByTitle(mapConfig, "projectPopup");
        mapConfig.map.on("click",
                         event => {
                             if (mapConfig.map.hasFeatureAtPixel(event.pixel)) {
                                 let clickedFeatures = [];
                                 mapConfig.map.forEachFeatureAtPixel(event.pixel, feature => clickedFeatures.push(feature));
                                 this.showProjectPopup(mapConfig, overlay, documentRoot, clickedFeatures[0]);
                             } else {
                                 overlay.setPosition(undefined);
                             }
                         });
        mercator.zoomMapToExtent(mapConfig, projectSource.getExtent());
        this.setState({projectMarkersShown: true});
    }

    showProjectPopup(mapConfig, overlay, documentRoot, feature) {
        if (mercator.isCluster(feature)) {
            overlay.setPosition(feature.get("features")[0].getGeometry().getCoordinates());
            this.setState({clusterExtent: mercator.getClusterExtent(feature),
                           clickedFeatures: feature.get("features")});
        } else {
            overlay.setPosition(feature.getGeometry().getCoordinates());
            this.setState({clusterExtent: [],
                           clickedFeatures: feature.get("features")});
        }
    }

    render() {
        return (
            <div id="mapPanel" className={this.props.showHideSideBar}>
                <div className="row no-gutters ceo-map-toggle">
                    <div id="togbutton" className="button col-xl-1 bg-lightgray d-none d-xl-block" onClick={this.props.toggleSidebar}>
                        <div className="row h-100">
                            <div className="col-lg-12 my-auto no-gutters text-center">
                                <span id="tog-symb"><i className="fa fa-caret-left"></i></span>
                            </div>
                        </div>
                    </div>
                    <div className="col-xl-11 mr-0 ml-0 bg-lightgray">
                        <div id="home-map-pane" style={{width: "100%", height: "100%", position: "fixed"}}></div>
                    </div>
                </div>
                <ProjectPopup mapConfig={this.state.mapConfig}
                              clusterExtent={this.state.clusterExtent}
                              features={this.state.clickedFeatures}
                              documentRoot={this.props.documentRoot}/>
            </div>
        );
    }
}

class SideBar extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            filteredInstitutions: [],
            checkedInstitutions:[],
            institutions: [],
            tempChecked:[]
        };
        this.filterCall=this.filterCall.bind(this);
        this.filterAlphabetically=this.filterAlphabetically.bind(this);
    }
    componentDidMount() {
        // Fetch institutions
        fetch(this.props.documentRoot + "/get-all-institutions")
            .then(response => response.json())
            .then(data => {

                var tmp=[];
                var x=[];
                data.map((inst) => {
                    x.push(inst.name.substring(0, 1))
                });
                var y = x.filter(function (item, pos) {
                    return x.indexOf(item) == pos;
                });
                y.map((inst) => {
                    tmp.push({"alphabet":inst,"isChecked":false});
                });
                var tchecked=[];
                y.map(t=>{
                    tchecked.push({"alphabet":t,"isChecked":false});
                });
                this.setState({tempChecked:tchecked});
                this.setState({filteredInstitutions: data,institutions:data})});
    }

    filterCall(e) {
        const filterText = e.target.value;
        if (filterText != '') {
            const filtered = this.state.institutions.filter(inst => (inst.name.toLocaleLowerCase()).includes(filterText.toLocaleLowerCase()));
            if (filtered.length > 0) {
                this.setState({filteredInstitutions: filtered});
            }
            else {
                this.setState({filteredInstitutions: []});
            }
        }
        else {
            this.setState({filteredInstitutions: this.state.institutions});
        }
        var x=this.state.checkedInstitutions;
        var result = this.state.filteredInstitutions.filter(function(n) {
            return x.indexOf(n) > -1;
        });
    }
    filterAlphabetically(e) {
        var tchecked = this.state.tempChecked;
        tchecked.map((checkedInst) => {
            if (checkedInst["alphabet"].toLocaleUpperCase() == e.target.innerHTML.toLocaleUpperCase() && checkedInst["isChecked"] == false) {
                checkedInst["isChecked"] = true;
            }
            else if (checkedInst["alphabet"].toLocaleUpperCase() == e.target.innerHTML.toLocaleUpperCase() && checkedInst["isChecked"] == true) {
                checkedInst["isChecked"] = false;
            }
        });
        this.setState({tempChecked: tchecked});
        let checkedInsts = this.state.checkedInstitutions;
        let checkedInst = tchecked.filter((ch) => (ch["alphabet"].toLocaleUpperCase() == e.target.innerHTML.toLocaleUpperCase()));
        if (checkedInst[0]["isChecked"] == true) {
            const filtered = this.state.institutions.filter(inst => (inst.name.substring(0, 1).toLocaleLowerCase()) == checkedInst[0]["alphabet"].toLocaleLowerCase());
            let finalArr = checkedInsts.concat(filtered);
            if (finalArr.length > 0) {
                this.setState({checkedInstitutions: finalArr});
                this.setState({filteredInstitutions: finalArr});
            } else {
                this.setState({checkedInstitutions: []});
                this.setState({filteredInstitutions: []});
            }
        }
        else if (checkedInst[0]["isChecked"] == false) {
            const filtered = this.state.checkedInstitutions.filter(inst => (inst.name.substring(0, 1).toLocaleLowerCase()) != checkedInst[0]["alphabet"].toLocaleLowerCase());
            if (filtered.length > 0) {
                this.setState({filteredInstitutions: filtered});
            }
            else {
                this.setState({filteredInstitutions: this.state.institutions});
            }
            this.setState({checkedInstitutions: filtered});
        }
    }
    render() {
        return (
            <div id="lPanel" className={this.props.showHideLpanel}>
                <div className="bg-darkgreen">
                    <h1 className="tree_label" id="panelTitle">Institutions</h1>
                </div>
                <ul className="tree">
                    <CreateInstitutionButton userName={this.props.userName} documentRoot={this.props.documentRoot}/>
                    <InstitutionFilter documentRoot={this.props.documentRoot} filterCall={this.filterCall}/>
                    <div className="form-control" style={{textAlign:"center"}}>
                        <FilterAlphabetically filteredInstitutions={this.state.institutions} filterAlphabetically={this.filterAlphabetically} tempChecked={this.state.tempChecked}/>
                    </div>
                    <InstitutionList filteredInstitutions={this.state.filteredInstitutions} projects={this.props.projects}
                                     documentRoot={this.props.documentRoot}/>
                </ul>
            </div>
        );
    }
}

function InstitutionFilter(props) {
    return (
        <div id="filter-institution" className="form-control">
            <input type="text" id="filterInstitution" autoComplete="off" placeholder="Filter by Institution Name"
                   className="form-control"
                   onChange={(e) => props.filterCall(e)}/>
        </div>
    );
}

function CreateInstitutionButton(props) {
    if (props.userName != "") {
        return (
            <a className="create-institution" href={props.documentRoot + "/create-institution/0"}>
                <li className="bg-yellow text-center p-2"><i className="fa fa-file"></i> Create New Institution</li>
            </a>
        );
    } else {
        return (
            <span></span>
        );
    }
}

function InstitutionList(props) {
    return(
        props.filteredInstitutions.map(
            (institution, uid) =>
                <Institution key={uid}
                             id={institution.id}
                             name={institution.name}
                             documentRoot={props.documentRoot}
                             projects={props.projects.filter(project => project.institution == institution.id)}/>
        )
    );
}

function FilterAlphabetically(props) {
    let tmp=props.tempChecked.sort(function(a,b){
        if( a["alphabet"].toLocaleUpperCase() > b["alphabet"].toLocaleUpperCase()){
            return 1;
        }else if( a["alphabet"].toLocaleUpperCase()  < b["alphabet"].toLocaleUpperCase() ){
            return -1;
        }
        return 0;
    });
    return (
       tmp.map((letter, uid) =>
            <React.Fragment key={uid}>
                <button className={letter["isChecked"]==true?"btn btn-sm bg-lightgreen":"btn btn-sm btn-outline-lightgreen"} onClick={(e)=>props.filterAlphabetically(e)}>{letter["alphabet"].toLocaleUpperCase()}</button>
            </React.Fragment>
        )
    );
}

function Institution(props) {
    return (
        <li>
            <div className="btn bg-lightgreen btn-block m-0 p-2 rounded-0"
                 data-toggle="collapse"
                 href={"#collapse" + props.id}
                 role="button"
                 aria-expanded="false">
                <div className="row">
                    <div className="col-lg-10 my-auto">
                        <p className="tree_label text-white m-0"
                           htmlFor={"c" + props.id}>
                            <input type="checkbox" className="d-none" id={"c" + props.id}/>
                            <span className="">{props.name}</span>
                        </p>
                    </div>
                    <div className="col-lg-1">
                        <a className="institution_info btn btn-sm btn-outline-lightgreen"
                           href={props.documentRoot + "/review-institution/" + props.id}>
                            <i className="fa fa-info" style={{color: "white"}}></i>
                        </a>
                    </div>
                </div>
            </div>
            <ProjectList id={props.id} projects={props.projects} documentRoot={props.documentRoot}/>
        </li>
    );
}

function ProjectList(props) {
    return (
        <div className="collapse" id={"collapse" + props.id}>
            {
                props.projects.map(
                    (project, uid) =>
                        <Project key={uid}
                                 id={project.id}
                                 institutionId={props.id}
                                 editable={project.editable}
                                 name={project.name}
                                 documentRoot={props.documentRoot}/>
                )
            }
        </div>
    );
}

function Project(props) {
    if (props.editable == true) {
        return (
            <div className="bg-lightgrey text-center p-1 row px-auto">
                <div className="col-lg-8 pr-lg-1">
                    <a className="view-project btn btn-sm btn-outline-lightgreen btn-block"
                       href={props.documentRoot + "/collection/" + props.id}>
                        {props.name}
                    </a>
                </div>
                <div className="col-lg-4 pl-lg-0">
                    <a className="edit-project btn btn-sm btn-outline-yellow btn-block"
                       href={props.documentRoot + "/review-project/" + props.id}>
                        <i className="fa fa-edit"></i> Review
                    </a>
                </div>
            </div>
        );
    } else {
        return (
            <div className="bg-lightgrey text-center p-1 row">
                <div className="col mb-1 mx-0">
                    <a className="btn btn-sm btn-outline-lightgreen btn-block"
                       href={props.documentRoot + "/collection/" + props.id}>
                        {props.name}
                    </a>
                </div>
            </div>
        );
    }
}

class ProjectPopup extends React.Component {
    componentDidMount() {
        // There is some kind of bug in attaching this onClick handler directly to its button in render().
        document.getElementById("zoomToCluster").onclick = () => {
            mercator.zoomMapToExtent(this.props.mapConfig, this.props.clusterExtent);
            mercator.getOverlayByTitle(this.props.mapConfig, "projectPopup").setPosition(undefined);
        };
    }

    render() {
        return (
            <div id="projectPopUp">
                <div className="cTitle">
                    <h1>{this.props.features.length > 1 ? "Cluster info" : "Project info"}</h1>
                </div>
                <div className="cContent" style={{padding:"10px"}}>
                    <table className="table table-sm">
                        <tbody>
                            {
                                this.props.features.map((feature, uid) =>
                                    <React.Fragment key={uid}>
                                        <tr className="d-flex" style={{borderTop: "1px solid gray"}}>
                                            <td className="small col-6 px-0 my-auto">Name</td>
                                            <td className="small col-6 pr-0">
                                                <a href={this.props.documentRoot + "/collection/" + feature.get("projectId")}
                                                   className="btn btn-sm btn-block btn-outline-lightgreen"
                                                   style={{
                                                       whiteSpace: "nowrap",
                                                       overflow: "hidden",
                                                       textOverflow: "ellipsis"
                                                   }}>
                                                    {feature.get("name")}
                                                </a>
                                            </td>
                                        </tr>
                                        <tr className="d-flex">
                                            <td className="small col-6 px-0 my-auto">Description</td>
                                            <td className="small col-6 pr-0">{feature.get("description")}</td>
                                        </tr>
                                        <tr className="d-flex" style={{borderBottom: "1px solid gray"}}>
                                            <td className="small col-6 px-0 my-auto">Number of plots</td>
                                            <td className="small col-6 pr-0">{feature.get("numPlots")}</td>
                                        </tr>
                                    </React.Fragment>
                                )
                            }
                        </tbody>
                    </table>
                </div>
                <button id="zoomToCluster"
                        className="mt-0 mb-0 btn btn-sm btn-block btn-outline-yellow"
                        style={{
                            cursor: "pointer",
                            minWidth: "350px",
                            display: this.props.features.length > 1 ? "block" : "none"
                        }}>
                    <i className="fa fa-search-plus"></i> Zoom to cluster
                </button>
            </div>
        );
    }
}

export function renderHomePage(args) {
    ReactDOM.render(
        <Home documentRoot={args.documentRoot} userId={args.userId} userName={args.userName}/>,
        document.getElementById("home")
    );
}
