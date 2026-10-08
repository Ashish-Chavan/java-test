import React from 'react';
import { create } from 'react-test-renderer';
import ManagerTable from './ManagerTable';

describe('ManagerTable', () => {
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
