import './App.css';
import '../themes/default.scss';

import { isUndefined } from 'lodash';
import isNull from 'lodash/isNull';
import React, { useEffect, useState } from 'react';
import { Route, Router, Switch } from 'react-router-dom';

import { AppCtxProvider, updateActiveStyleSheet } from '../context/AppCtx';
import buildSearchParams from '../utils/buildSearchParams';
import detectActiveThemeMode from '../utils/detectActiveThemeMode';
import history from '../utils/history';
import lsPreferences from '../utils/localStoragePreferences';
import AlertController from './common/AlertController';
import ControlPanelView from './controlPanel';
import HomeView from './home';
import Footer from './navigation/Footer';
import Navbar from './navigation/Navbar';
import NotFound from './notFound';
import PackageView from './package';
import SearchView from './search';
import StarredPackagesView from './starredPackages';

const ScrollMemory = require('react-router-scroll-memory');

const getQueryParam = (query: string, param: string): string | undefined => {
  let result;
  const p = new URLSearchParams(query);
  if (p.has(param) && !isNull(p.get(param))) {
    result = p.get(param) as string;
  }
  return result;
};

export default function App() {
  const [isSearching, setIsSearching] = useState(false);
  const [activeInitialTheme, setActiveInitialTheme] = useState<string | null>(null);
  const [scrollPosition, setScrollPosition] = useState<undefined | number>(undefined);

  useEffect(() => {
    const activeProfile = lsPreferences.getActiveProfile();
    const theme = activeProfile.theme.automatic
      ? detectActiveThemeMode()
      : activeProfile.theme.efective || activeProfile.theme.configured;
    if (!isUndefined(theme)) {
      updateActiveStyleSheet(theme);
      setActiveInitialTheme(theme);
    }
  }, []);

  if (isNull(activeInitialTheme)) return null;

  return (
    <AppCtxProvider>
      <Router history={history}>
        <div className="d-flex flex-column min-vh-100 position-relative">
          <ScrollMemory />
          <AlertController />
          <Switch>
            <Route
              path={['/', '/verify-email', '/login', '/accept-invitation', '/oauth-failed']}
              exact
              render={({ location }) => (
                <div className="d-flex flex-column flex-grow-1">
                  <Navbar
                    isSearching={isSearching}
                    redirect={getQueryParam(location.search, 'redirect') || undefined}
                    fromHome
                  />
                  <HomeView
                    isSearching={isSearching}
                    emailCode={getQueryParam(location.search, 'code')}
                    orgToConfirm={getQueryParam(location.search, 'org')}
                    onOauthFailed={location.pathname === '/oauth-failed'}
                  />
                  <Footer />
                </div>
              )}
            />

            <Route
              path="/packages/search"
              exact
              render={({ location }: any) => {
                const searchParams = buildSearchParams(location.search);
                return (
                  <>
                    <Navbar isSearching={isSearching} searchText={searchParams.tsQueryWeb} />
                    <div className="d-flex flex-column flex-grow-1">
                      <SearchView
                        {...searchParams}
                        isSearching={isSearching}
                        setIsSearching={setIsSearching}
                        scrollPosition={scrollPosition}
                        setScrollPosition={setScrollPosition}
                        fromDetail={location.state ? location.state.hasOwnProperty('fromDetail') : false}
                      />
                    </div>
                  </>
                );
              }}
            />

            <Route
              path="/packages/:repositoryKind/:repositoryName/:packageName/:version?"
              exact
              render={({ location, match }) => (
                <>
                  <Navbar isSearching={isSearching} />
                  <div className="d-flex flex-column flex-grow-1">
                    <PackageView
                      hash={location.hash}
                      channel={getQueryParam(location.search, 'channel')}
                      visibleModal={getQueryParam(location.search, 'modal') || undefined}
                      visibleValuesSchemaPath={getQueryParam(location.search, 'path') || undefined}
                      {...location.state}
                      {...match.params}
                    />
                  </div>
                </>
              )}
            />

            <Route
              path="/control-panel/:section?/:subsection?"
              exact
              render={({ location, match }) => (
                <>
                  <Navbar isSearching={isSearching} privateRoute />
                  <div className="d-flex flex-column flex-grow-1">
                    <ControlPanelView
                      {...match.params}
                      userAlias={getQueryParam(location.search, 'user-alias') || undefined}
                      organizationName={getQueryParam(location.search, 'org-name') || undefined}
                      repoName={getQueryParam(location.search, 'repo-name') || undefined}
                    />
                  </div>
                  <Footer />
                </>
              )}
            />

            <Route
              path="/packages/starred"
              exact
              render={() => (
                <>
                  <Navbar isSearching={isSearching} privateRoute />
                  <div className="d-flex flex-column flex-grow-1">
                    <StarredPackagesView />
                  </div>
                  <Footer />
                </>
              )}
            />

            <Route
              render={() => (
                <>
                  <Navbar isSearching={isSearching} />
                  <NotFound />
                  <Footer />
                </>
              )}
            />
          </Switch>
        </div>
      </Router>
    </AppCtxProvider>
  );
}
