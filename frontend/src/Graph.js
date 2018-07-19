import React from 'react';
import PropTypes from 'prop-types';
import { withStyles } from '@material-ui/core/styles';

import vis from "vis";

const styles = {
}

const dot = `
digraph {

ink -> user;
edge_list_link -> list;
edge_list_link -> link;
role_privilege -> role;
role_privilege -> privilege;
person -> user;
person_phone -> person;
person_phone -> phone;
appointment -> user;
appointment -> address;
person_appointment -> appointment;
person_appointment -> person;
list_item -> list;
list_item -> user;
list -> user;
edge_link_link -> link;
edge_link_link -> link;
edge_link_person -> link;
edge_link_person -> person;
edge_link_appointment -> link;
edge_link_appointment -> appointment;
edge_person_appointment -> person;
edge_person_appointment -> appointment;
edge_person_list -> person;
edge_person_list -> list;
edge_appointment_link -> appointment;
edge_appointment_link -> link;
edge_list_list -> list;
edge_list_list -> list;
edge_list_person -> list;
edge_list_person -> person;
edge_list_appointment -> list;
edge_list_appointment -> appointment;
user_in_role -> user;
user_in_role -> role;
person_address -> person;
person_address -> address;
person_email -> person;
person_email -> email;
edge_link_list -> link;
edge_link_list -> list;
edge_person_link -> person;
edge_person_link -> link;
edge_person_person -> person;
edge_person_person -> person;
edge_appointment_person -> appointment;
edge_appointment_person -> person;
edge_appointment_appointment -> appointment;
edge_appointment_appointment -> appointment;
edge_appointment_list -> appointment;
edge_appointment_list -> list;
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
      nodes: parsedData.nodes,
      edges: parsedData.edges
    }  
    let options = parsedData.options;
    options.nodes = {
      shape: 'dot',
      scaling:{
        label: {
          min:8,
          max:20
        }
      }
    };

      const network = new vis.Network(this.graph.current, data, options);
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

