import React from 'react';
import { mount } from 'enzyme';
import { create } from 'react-test-renderer';
import ManagerTable from './ManagerTable';

describe('ManagerTable', () => {
  describe('Change view according state', () => {
    test('Should show loading component when data is not ready', () => {
      const wrapper = mount(<ManagerTable />);
      expect(wrapper.find('.loader-page')).toBeTruthy();
    });
  });

  describe('Snapshots', () => {
    test('Should match snapshot when is called', () => {
      const wrapper = create(
        <ManagerTable />,
      );

      expect(wrapper.toJSON()).toMatchSnapshot();
      wrapper.unmount();
    });
  });
});
