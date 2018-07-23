import React from 'react';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';
import { has, isEmpty, head }  from 'lodash';

import vis from "vis";

const styles = {
}
// info [label = "*About*\nThis graph shows the relation between\nthe different parts of _rasmus_.\nMost of the nodes are linked\n to the sources of _rasmus.", url = "https://github.com/enter-haken/rasmus"]
const dot = `
graph {

otp [label = "*OTP tree*\nprocess configuration", url = "https://github.com/enter-haken/rasmus/blob/master/lib/rasmus_app.ex"];
router [label ="*router*\ncowboy router", url="https://github.com/enter-haken/rasmus/blob/master/lib/web/router.ex"]
counter [label = "*counter*\nlisten to notifications\nfrom database", url = "https://github.com/enter-haken/rasmus/blob/master/lib/core/counter.ex"]
inbound [label = "*inbound*\nsend requests towards\nthe database", url = "https://github.com/enter-haken/rasmus/blob/master/lib/core/inbound.ex"]
manager [label = "*manager*\nexecute the\ndatabase manager", url = "https://github.com/enter-haken/rasmus/blob/master/lib/core/manager.ex"]
client [label = "*client*\nreact / visjs app", url = "https://github.com/enter-haken/rasmus/tree/master/frontend"]
configuration [label = "*configuration*\ndatabase configuration", url = "https://github.com/enter-haken/rasmus/tree/master/config"]
database [label = "*PostgreSQL*", url ="https://github.com/enter-haken/rasmus/tree/master/database_scripts"]
transfer [label = "*transfer*\ninterface table", url = "https://github.com/enter-haken/rasmus/blob/master/database_scripts/transfer.sql"]
postcreate [label = "*postcreate*\ntable manipulation\nafter DDL", url = "https://github.com/enter-haken/rasmus/blob/master/database_scripts/postcreate.sql"]
crud [label = "*CRUD*\ngeneric CREATE, READ\nUPDATE, DELETE\nfunctions", url = "https://github.com/enter-haken/rasmus/blob/master/database_scripts/crud.sql"]

otp -- router [ label = "supervises"]
otp -- counter [ label = "supervises"]
otp -- inbound [ label = "supervises"]
otp -- manager [ label = "supervises"]

counter -- manager [ label = "executes the\nmanager"]
counter -- database [ label ="listens for\ndatabase notifications"]
router -- client [label = "serves"]
inbound -- transfer [label = "insert request"]
database -- transfer 
database -- postcreate
database -- configuration
database -- crud

}
`
class Graph extends React.Component {
  constructor(props) {
    super(props);
    this.graph = React.createRef();
  }
  componentDidMount() {
    let parsedData = vis.network.convertDot(dot);
    let data = {
      nodes: parsedData.nodes.map(node => {
        if (node.id == "info") {
          node.x = 0;
          node.y = 0;
        }
       return node;
      }),
      edges: parsedData.edges
    }  
    console.log(data);
    let options = parsedData.options;

    options.edges = {
      font: {
        size: 12,
        multi: 'md',
        face: 'sans'
      }
    };
    options.nodes =  {
      shape: 'box',
      font: {
        bold: {
          color: '#0077aa'
        },
        face: 'sans',
        size: 12,
        multi : 'md'
      },
      margin : 8 
    };

    options.physics = {
      enabled: true,
      barnesHut: {
        avoidOverlap : 0.5 
      }
    };
    
    this.network = new vis.Network(this.graph.current, data, options);
    this.network.on("click", (params) => {
      if (isEmpty(params.nodes)) {
        return;
      }
      let clicked_node = this.network.body.data.nodes.get(head(params.nodes));

      if (clicked_node && has(clicked_node, 'url')){
        var win = window.open(clicked_node.url, '_blank');
        win.focus();
      }
    });
  }

  render() {
    const { classes } = this.props;

    const style = {
      position : "fixed",
      top: 86,
      right : 0,
      bottom: 0,
      left: 0,
      width : "100%",
      height : "100%"
    }

    return (
      <div ref={this.graph} style={style}></div>
    ); 
  }
};

export default Graph;
