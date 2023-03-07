import PropTypes from 'prop-types';
import React from 'react';
import ImmutablePureComponent from 'react-immutable-pure-component';
import ImmutablePropTypes from 'react-immutable-proptypes';
import { defineMessages, injectIntl, FormattedMessage } from 'react-intl';
import { connect } from 'react-redux';
import ColumnHeader from 'mastodon/components/column_header';
import Icon from 'mastodon/components/icon';
import { fetchReactions } from 'mastodon/actions/interactions';
import LoadingIndicator from 'mastodon/components/loading_indicator';
import ScrollableList from 'mastodon/components/scrollable_list';
import AccountContainer from 'mastodon/containers/account_container';
import Column from 'mastodon/features/ui/components/column';
import { Helmet } from 'react-helmet';
import EmojiView from '../../components/emoji_view';

const messages = defineMessages({
  refresh: { id: 'refresh', defaultMessage: 'Refresh' },
});

const mapStateToProps = (state, props) => ({
  accountIds: state.getIn(['user_lists', 'reacted_by', props.params.statusId]),
});

export default @connect(mapStateToProps)
@injectIntl
class Reactions extends ImmutablePureComponent {

  static propTypes = {
    params: PropTypes.object.isRequired,
    dispatch: PropTypes.func.isRequired,
    accountIds: ImmutablePropTypes.list,
    multiColumn: PropTypes.bool,
    intl: PropTypes.object.isRequired,
  };

  componentWillMount () {
    if (!this.props.accountIds) {
      this.props.dispatch(fetchReactions(this.props.params.statusId));
    }
  }

  componentWillReceiveProps (nextProps) {
    if (nextProps.params.statusId !== this.props.params.statusId && nextProps.params.statusId) {
      this.props.dispatch(fetchReactions(nextProps.params.statusId));
    }
  }

  handleRefresh = () => {
    this.props.dispatch(fetchReactions(this.props.params.statusId));
  };

  render () {
    const { intl, accountIds, multiColumn } = this.props;

    if (!accountIds) {
      return (
        <Column>
          <LoadingIndicator />
        </Column>
      );
    }

    let groups = {};
    for (const reaction of accountIds) {
      const key = reaction.account.id;
      const value = reaction;
      if (!groups[key]) groups[key] = [value];
      else groups[key].push(value);
    }

    const emptyMessage = <FormattedMessage id='empty_column.reactions' defaultMessage='No one has reacted with emoji this post yet. When someone does, they will show up here.' />;

    return (
      <Column bindToDocument={!multiColumn}>
        <ColumnHeader
          showBackButton
          multiColumn={multiColumn}
          extraButton={(
            <button type='button' className='column-header__button' title={intl.formatMessage(messages.refresh)} aria-label={intl.formatMessage(messages.refresh)} onClick={this.handleRefresh}><Icon id='refresh' /></button>
          )}
        />

        <ScrollableList
          scrollKey='reactions'
          emptyMessage={emptyMessage}
          bindToDocument={!multiColumn}
        >
          {Object.keys(groups).map((key) =>(
            <AccountContainer key={key} id={key} withNote={false}>
              <div style={ { 'maxWidth': '100px' } }>
                {groups[key].map((value, index2) => <EmojiView key={index2} name={value.name} url={value.url} staticUrl={value.static_url} />)}
              </div>
            </AccountContainer>
          ))}
        </ScrollableList>

        <Helmet>
          <meta name='robots' content='noindex' />
        </Helmet>
      </Column>
    );
  }

}
