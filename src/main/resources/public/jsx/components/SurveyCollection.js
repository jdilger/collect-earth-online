import React, { Fragment } from "react";

import { removeEnumerator } from "../utils/SurveyUtils"

export class SurveyQuestions extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            topLevelNodeIds: [],
            currentNodeIndex: 0
        }
    }  

    componentDidMount() {
        const topLevelNodeIds = this.props.surveyQuestions
                                .filter(sq => sq.parentQuestion == -1)
                                .sort((a, b) => a.id - b.id)
                                .map(sq => sq.id);
        this.setState({
            topLevelNodeIds: topLevelNodeIds
        });
    }

    componentDidUpdate(prevProps, prevState) {
        if (this.state.currentNodeIndex !== prevState.currentNodeIndex) {
            this.props.setSelectedQuestion(this.getNodeById(this.state.topLevelNodeIds[this.state.currentNodeIndex]));
        }
    }

    prevSurveyQuestionTree = () => {
        if (this.state.currentNodeIndex > 0) {
            this.setState({currentNodeIndex: this.state.currentNodeIndex - 1});
        } else {
            alert("There are no previous questions.");
        }
    }

    nextSurveyQuestionTree = () => {
        if (this.state.currentNodeIndex < this.state.topLevelNodeIds.length - 1) {
            this.setState({currentNodeIndex: this.state.currentNodeIndex + 1});
        } else {
            alert("There are no more questions.");
        }
    }

    setSurveyQuestionTree = (index) => this.setState({currentNodeIndex: index});

    checkAllSelected = (currentQuestionId) => {
        const { surveyQuestions } = this.props;
        const { visible, answered } = surveyQuestions.find(sv => sv.id === currentQuestionId);
        const childQuestions = surveyQuestions.filter(sv => sv.parentQuestion === currentQuestionId);

        if (childQuestions.length === 0) {
            return visible === answered;
        } else {
            return visible === answered && childQuestions.every(cq => this.checkAllSelected(cq.id));
        }   
    }

    getTopColor = (node) => this.checkAllSelected(node.id)
                                ? "0px 0px 15px 4px green inset"
                                : node.answered > 0
                                    ? "0px 0px 15px 4px yellow inset"
                                    : "0px 0px 15px 4px red inset";
    
    getNodeById = (id) => this.props.surveyQuestions.find(sq => sq.id === id);

    render() {
        return (
            <fieldset className="mb-3 justify-content-center text-center">
                <h3>Survey Questions</h3>
                {this.props.surveyQuestions.length > 0
                ?
                    <div className="SurveyQuestions__questions">
                        <div className="SurveyQuestions__top-questions">
                            <button 
                                id="prev-survey-question" 
                                className="btn btn-outline-lightgreen m-2"
                                onClick={this.prevSurveyQuestionTree}
                                disabled={this.state.currentNodeIndex === 0}
                                style={{opacity: this.state.currentNodeIndex === 0 ? "0.25" : "1.0"}}
                            >
                                {`<`}
                            </button>
                            {this.state.topLevelNodeIds.map((node, i) => 
                                <button 
                                    id="top-select" 
                                    key={i}
                                    className="btn btn-outline-lightgreen m-2"
                                    onClick={() => this.setSurveyQuestionTree(i)}
                                    style={{boxShadow: `${(i === this.state.currentNodeIndex)
                                        ? "0px 0px 2px 2px black inset,"
                                        : ""}
                                        ${this.getTopColor(this.getNodeById(node))}
                                    `}}
                                >
                                {i+1}
                                </button>
                            )}
                            <button 
                                id="next-survey-question" 
                                className="btn btn-outline-lightgreen"
                                onClick={this.nextSurveyQuestionTree}
                                disabled={this.state.currentNodeIndex === this.state.topLevelNodeIds.length - 1}
                                style={{opacity: this.state.currentNodeIndex === this.state.topLevelNodeIds.length - 1 ? "0.25" : "1.0"}}
                            >
                                {`>`}
                            </button>
                        </div>
                        {this.state.topLevelNodeIds.length > 0 &&
                            <SurveyQuestionTree
                                surveyNode={this.getNodeById(this.state.topLevelNodeIds[this.state.currentNodeIndex])}
                                surveyQuestions={this.props.surveyQuestions}
                                setCurrentValue={this.props.setCurrentValue}
                                selectedQuestion={this.props.selectedQuestion}
                                setSelectedQuestion={this.props.setSelectedQuestion}
                                higharcyLabel=""
                            />
                        }
                    </div>
                :
                    <h3>This project is missing survey questions!</h3>
                }
            </fieldset>
        );
    }
}

class SurveyQuestionTree extends React.Component  {
    constructor(props) {
        super(props);
        this.state = {
            showAnswers: true
        }
    }  

    toggleShowAnswers = () => this.setState({ showAnswers: !this.state.showAnswers });

    render() {
        const childNodes = this.props.surveyQuestions.filter(surveyNode => surveyNode.parentQuestion == this.props.surveyNode.id);
        const shadowColor = this.props.surveyNode.answered === 0 
                            ? "0px 0px 15px 4px red inset"
                            : this.props.surveyNode.answered === this.props.surveyNode.visible
                                ? "0px 0px 15px 4px green inset"
                                : "0px 0px 15px 4px yellow inset";
        return (
            <fieldset className={"mb-1 justify-content-center text-center"}>
                <div className="SurveyQuestionTree__question-buttons btn-block my-2 d-flex">
                    <button
                        id={this.props.surveyNode.question + "_" + this.props.surveyNode.id}
                        className="text-center btn btn-outline-lightgreen btn-sm text-bold px-3 py-2"
                        onClick={this.toggleShowAnswers}
                    >
                        {this.state.showAnswers ? <span>-</span> : <span>+</span>}
                    </button>
                    <button
                        id={this.props.surveyNode.question + "_" + this.props.surveyNode.id}
                        className="text-center btn btn-outline-lightgreen btn-sm btn-block"
                        style={{boxShadow: `${(this.props.surveyNode.id === this.props.selectedQuestion.id)
                                    ? "0px 0px 2px 2px black inset,"
                                    : ""}
                                    ${shadowColor}
                                `}}
                        onClick={() => this.props.setSelectedQuestion(this.props.surveyNode)}
                    >
                    {this.props.higharcyLabel + removeEnumerator(this.props.surveyNode.question)}
                    </button>
                </div>

                {this.state.showAnswers &&
                    <SurveyAnswers
                        componentType={this.props.surveyNode.componentType}
                        dataType={this.props.surveyNode.dataType}
                        surveyNode={this.props.surveyNode}
                        answers={this.props.surveyNode.answers}
                        setCurrentValue={this.props.setCurrentValue}
                    />
                }
                {
                    childNodes.map((childNode, uid) =>
                        <Fragment key={uid}>
                            {this.props.surveyQuestions.find(sq => sq.id === childNode.id).visible > 0 &&
                            <SurveyQuestionTree 
                                key={uid}
                                surveyNode={childNode}
                                surveyQuestions={this.props.surveyQuestions}
                                setCurrentValue={this.props.setCurrentValue}
                                selectedQuestion={this.props.selectedQuestion}
                                setSelectedQuestion={this.props.setSelectedQuestion}
                                higharcyLabel={this.props.higharcyLabel + "- "}
                            />
                            }
                        </Fragment>
                    )
                }
            </fieldset>
        );
    }
}

function AnswerButton(props){
    return <ul className={"samplevalue justify-content-center"}>
                {props.answers.map((ans, uid) => 
                    <li key={uid} className="mb-1">
                        <button 
                            type="button"
                            className="btn btn-outline-darkgray btn-sm btn-block pl-1"
                            id={ans.answer + "_" + ans.id}
                            name={ans.answer + "_" + ans.id}
                            // style={{
                            //     boxShadow: (props.selectedAnswers[props.question] == ans.answer)
                            //         ? "0px 0px 4px 4px black inset, 0px 0px 4px 4px white inset"
                            //         : "initial"
                            // }}
                            onClick={() => props.setCurrentValue(props.surveyNode, ans.id, ans.answer)}
                        >
                            <div className="circle"
                                style={{
                                    backgroundColor: ans.color,
                                    border: "1px solid",
                                    float: "left",
                                    marginTop: "4px"
                                }}>
                            </div>
                            <span className="small">{ans.answer}</span>
                        </button>
                    </li>
                )}
            </ul>
}

function AnswerRadioButton(props) {
    return <ul className={"samplevalue justify-content-center"}>
                {props.answers.map((ans, uid) => 
                    <li key={uid} className="mb-1">
                        <button 
                            type="button"
                            className="btn-outline-darkgray btn-sm btn-block pl-1"
                            id={ans.answer + "_" + ans.id}
                            name={ans.answer + "_" + ans.id}
                            onClick={() => props.setCurrentValue(props.surveyNode, ans.id, ans.answer)}
                        >
                            <div className="circle"
                                style={{
                                    border: "1px solid",
                                    float: "left",
                                    marginTop: "4px",
                                    boxShadow: "0px 0px 2px 0px " + ans.color + " inset"
                                }}>
                            </div>
                            <span className="small">{ans.answer}</span>
                        </button>
                    </li>
                )}
            </ul>
}

class AnswerInput extends React.Component{
    constructor(props) {
        super(props);
        this.state = {
            newInput: "",
        };
    }

    componentDidUpdate(prevProps) {
        if (this.props.surveyNode.id !== prevProps.surveyNode.id) {
            this.setState({ newInput: "" })
        }
    }

    updateInputValue = (value) => this.setState({ newInput: value });
    
    render() {
        const { props } = this;
        // fix me, should not need map
        return props.answers.map(ans => (
                <div className="d-inline-flex">
                    <div className="pr-2 pt-2">
                        <div className="circle"
                            style={{
                                backgroundColor: ans.color,
                                border: "1px solid",
                            }}>
                        </div>
                    </div>
                    <input 
                        type={this.props.dataType}
                        className="form-control mr-2"
                        placeholder={ans.answer}
                        id={ans.answer + "_" + ans.id}
                        name={ans.answer + "_" + ans.id}
                        value={this.state.newInput}
                        onChange={e => this.updateInputValue(e.target.value)}
                    />
                    <input
                        id="save-input"
                        className="text-center btn btn-outline-lightgreen btn-sm"
                        type="button"
                        name="save-input"
                        value="Save"
                        onClick={() => {
                            props.setCurrentValue(props.surveyNode, ans.id, this.state.newInput)
                            this.setState({ newInput: ""})
                        }}
                    />
                </div>
        ));
    }
}

class AnswerDropDown extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            showDropdown: false
        }
    }  

    componentDidUpdate (prevProps) {
        if (this.props.surveyNode !== prevProps.surveyNode) {
            this.setState({showDropdown: false})
        }
    }
    
    toggleDropDown = () => this.setState({showDropdown: !this.state.showDropdown});
    
    render () {
        const options = this.props.answers.map((ans,uid) => 
            <div 
                key={uid} 
                onClick={() => {
                        this.props.setCurrentValue(this.props.surveyNode, ans.id, ans.answer);
                        this.setState({ showDropdown: false });
                    }
                }
                className="d-inline-flex py-2 border-bottom"
            >
                <div className="col-1">
                    <span 
                        className="dot" 
                        style={{  
                            height: "15px",
                            width: "15px", 
                            backgroundColor: ans.color, 
                            borderRadius: "50%", 
                            display: "inline-block"
                        }} 
                    />
                </div>
                <div className="col-11 text-left">
                    {ans.answer}
                </div>
            </div>
        );

        return (
            <div className="mb-1 d-flex flex-column align-items-start"> 
                <div className="dropdown ml-3" style={{ position: "relative",display: "inline-block"}}>
                    <button 
                        onClick={this.toggleDropDown} 
                        className="dropbtn" 
                        style={{
                            backgroundColor: "#31BAB0",
                            color: "white",
                            padding: "12px 24px",
                            fontSize: "16px", 
                            border: "none", 
                            cursor: "pointer"
                        }}
                    >
                        -Select-
                    </button>
                </div>
                <div 
                    id="dropdown-placeholder" 
                    className={"dropdown-content col-8" }
                >
                    <div 
                        id="myDropdown" 
                        className={"dropdown-content flex-column container" }
                        style={{ 
                            display: this.state.showDropdown ? "flex" : "none", 
                            position: "absolute", 
                            backgroundColor: "#f1f1f1",  
                            overflow: "auto", 
                            boxShadow: "0px 8px 16px 0px rgba(0,0,0,0.2)",
                            zIndex: "10"
                        }}
                    >
                        {options}
                    </div>
                </div>
            </div>
        );
    }
}

function SurveyAnswers(props) {
  if (props.componentType && props.componentType.toLowerCase() == "radiobutton") {
        return (<AnswerRadioButton 
                    answers={props.answers} 
                    surveyNode={props.surveyNode}
                    dataType={props.dataType}
                    setCurrentValue={props.setCurrentValue}
                />);
    } else if (props.componentType && props.componentType.toLowerCase() == "input") {
        return (<AnswerInput
                    answers={props.answers} 
                    surveyNode={props.surveyNode}
                    dataType={props.dataType}
                    setCurrentValue={props.setCurrentValue}
                />);
    } else if (props.componentType && props.componentType.toLowerCase() == "dropdown") {
        return (<AnswerDropDown 
                    answers={props.answers} 
                    surveyNode={props.surveyNode} 
                    childNodes={props.childNodes}  
                    setCurrentValue={props.setCurrentValue}
                />);
    } else {
        return (<AnswerButton 
                    answers={props.answers} 
                    surveyNode={props.surveyNode}
                    dataType={props.dataType}
                    setCurrentValue={props.setCurrentValue}
                />);
    }
}
