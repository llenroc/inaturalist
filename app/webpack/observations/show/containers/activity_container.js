import { connect } from "react-redux";
import Activity from "../components/activity";
import { addComment, confirmDeleteComment, addID, deleteID, restoreID } from "../ducks/observation";
import { setFlaggingModalState } from "../ducks/flagging_modal";
import { createFlag, deleteFlag } from "../ducks/flags";

function mapStateToProps( state ) {
  return {
    observation: state.observation,
    config: state.config
  };
}

function mapDispatchToProps( dispatch ) {
  return {
    setFlaggingModalState: ( newState ) => { dispatch( setFlaggingModalState( newState ) ); },
    addComment: ( body ) => { dispatch( addComment( body ) ); },
    deleteComment: ( id ) => { dispatch( confirmDeleteComment( id ) ); },
    addID: ( taxon, options ) => { dispatch( addID( taxon, options ) ); },
    deleteID: ( id ) => { dispatch( deleteID( id ) ); },
    restoreID: ( id ) => { dispatch( restoreID( id ) ); },
    createFlag: ( className, id, flag, body ) => {
      dispatch( createFlag( className, id, flag, body ) );
    },
    deleteFlag: id => { dispatch( deleteFlag( id ) ); }
  };
}

const ActivityContainer = connect(
  mapStateToProps,
  mapDispatchToProps
)( Activity );

export default ActivityContainer;
