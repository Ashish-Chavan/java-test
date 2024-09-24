package com.openreach.orfta.persistence.controller;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.TypedQuery;
import javax.persistence.criteria.CriteriaBuilder;
import javax.persistence.criteria.CriteriaQuery;
import javax.persistence.criteria.Expression;
import javax.persistence.criteria.Path;
import javax.persistence.criteria.Predicate;
import javax.persistence.criteria.Root;

import org.hibernate.Criteria;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.MockitoAnnotations;
import org.mockito.Spy;
import org.mockito.internal.stubbing.defaultanswers.ReturnsEmptyValues;
import org.mockito.invocation.InvocationOnMock;
import org.springframework.core.env.Environment;
import org.springframework.http.MediaType;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.RequestBuilder;
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openreach.orfta.persistence.dao.RecordingDaoImpl;
import com.openreach.orfta.persistence.datacontructor.DataConstructor;
import com.openreach.orfta.persistence.dto.EquinoxPriceAuditReqDTO;
import com.openreach.orfta.persistence.dto.EquinoxPriceTwoRequestDTO;
import com.openreach.orfta.persistence.dto.RepositoryRequestDTO;
import com.openreach.orfta.persistence.exceptions.PersistenceAdvicer;
import com.openreach.orfta.persistence.model.DUser;
import com.openreach.orfta.persistence.model.EquinoxPriceListEtwo;
import com.openreach.orfta.persistence.model.EquinoxPriceTwoAudit;
import com.openreach.orfta.persistence.model.RecordingDiscount;
import com.openreach.orfta.persistence.model.RecordingDiscountAudit;
import com.openreach.orfta.persistence.repository.DUserRepository;
import com.openreach.orfta.persistence.repository.RecordingDiscountAuditRepository;
import com.openreach.orfta.persistence.repository.RecordingDiscountHisRepository;
import com.openreach.orfta.persistence.repository.RecordingDiscountRepository;
import com.openreach.orfta.persistence.service.RecordingServiceImpl;
import com.openreach.orfta.persistence.util.RecordingDiscountUtil;
import com.openreach.orfta.persistence.util.TimeStampUtil;

@RunWith(SpringRunner.class)
@TestPropertySource("classpath:persistence.properties")
public class RecordingControllerTest extends DataConstructor {
	
	@InjectMocks
	RecordingController recordingController;

	@Spy
	@InjectMocks
	RecordingServiceImpl recordingService;

	@Spy
	@InjectMocks
	RecordingDaoImpl recordingDao;

	@Mock
	Environment env;

	@Mock
	DUserRepository dUserRepository;
	@Mock
	RecordingDiscountRepository recordingDiscountRepository;
	
	@Mock
	RecordingDiscountAuditRepository recordingDiscountAuditRepository;
	
	@Mock
	RecordingDiscountHisRepository recordingDiscountHisRepository;

	@Mock
	private EntityManager entityManager;

	@Mock
	Criteria cr;
	
	private CriteriaBuilder criteriaBuilderMock;

	private CriteriaQuery<?> criteriaQueryMock;

	
	@Spy
	@InjectMocks
	RecordingDiscountUtil recordingDiscountUtil;
	
	@Spy
	@InjectMocks
	TimeStampUtil timeStampUtil;
	
	private MockMvc mockMvc;
	private Root<?> personRootMock;
	TypedQuery mockedTypedQuery = fluentMock(TypedQuery.class);
	
	@Before
	public void init() {
		MockitoAnnotations.initMocks(this);
		this.mockMvc = MockMvcBuilders.standaloneSetup(recordingController).setControllerAdvice(new PersistenceAdvicer()).build();
		ReflectionTestUtils.setField(recordingController, "recordingService", recordingService);
		ReflectionTestUtils.setField(recordingService, "recordingDao", recordingDao);
		ReflectionTestUtils.setField(recordingDao, "recordingDiscountRepository", recordingDiscountRepository);
		ReflectionTestUtils.setField(recordingDao, "recordingDiscountAuditRepository",recordingDiscountAuditRepository);
		ReflectionTestUtils.setField(recordingDao, "recordingDiscountHisRepository", recordingDiscountHisRepository);
		ReflectionTestUtils.setField(recordingDao, "recordingDiscountUtil",	recordingDiscountUtil);
	}
	public static String asJsonString(final Object obj) {
		try {
			return new ObjectMapper().writeValueAsString(obj);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	public static <T> T fluentMock(final Class<T> type) {
		return Mockito.mock(type, Mockito.withSettings().defaultAnswer(new ReturnsEmptyValues() {
			@Override
			public Object answer(InvocationOnMock invocation) {
				Object defaultReturnValue = super.answer(invocation);
				if (type.equals(invocation.getMethod().getReturnType())) {
					return invocation.getMock();
				} else {
					return defaultReturnValue;
				}
			}
		}));
	}
	
	public void CommonmethodaddRepositoryDiscountTest(RepositoryRequestDTO requestDTO) {
		 requestDTO.setCreatedEin("1");
		 DUser user=new DUser();
		 user.setEmail("email.com");
		 RecordingDiscount recordingDiscount = new RecordingDiscount();
		 Mockito.when(recordingDiscountRepository.findByRowId(requestDTO.getRowId())).thenReturn(recordingDiscount);
		 Mockito.when(dUserRepository.findByEin(requestDTO.getCreatedEin())).thenReturn(user);
	}
	@Test
	public void addRepositoryDiscountTest() {
		RepositoryRequestDTO requestDTO=new  RepositoryRequestDTO();
		CommonmethodaddRepositoryDiscountTest(requestDTO);
		recordingController.addRepositoryDiscount(requestDTO);
		
	}
	@Test
	public void addRepositoryDiscountTestElse() {
		RepositoryRequestDTO requestElseAdd=new  RepositoryRequestDTO();
		CommonmethodaddRepositoryDiscountTest(requestElseAdd);
		RecordingDiscount dis =new RecordingDiscount();
		dis.setUniqueReferenceNo("123");
		Mockito.when(recordingDiscountRepository.getMaxRecord()).thenReturn(dis);
		recordingController.addRepositoryDiscount(requestElseAdd);
		
	}
	@Test
	public void modifyRepositoryDiscountTest() {
		RepositoryRequestDTO requestDTO1=new  RepositoryRequestDTO();
		CommonmethodaddRepositoryDiscountTest(requestDTO1);
		recordingController.modifyRepositoryDiscount(requestDTO1);
		
	}
	@Test(expected=Exception.class)
	public void modifyRepositoryDiscountTestElse() {
		RepositoryRequestDTO requestDTOElseModify=new  RepositoryRequestDTO();
		requestDTOElseModify.setAccnReference("hello");
		 Mockito.when(recordingDiscountRepository.findByRowId(requestDTOElseModify.getRowId())).thenReturn(null);
		recordingController.modifyRepositoryDiscount(requestDTOElseModify);
		
	}
	@Test
	public void deleteRepositoryDiscountTest() {
		RepositoryRequestDTO requestDTO2=new  RepositoryRequestDTO();
		CommonmethodaddRepositoryDiscountTest(requestDTO2);
		recordingController.deleteRepositoryDiscount(requestDTO2);
		
	}
	@Test(expected=Exception.class)
	public void deleteRepositoryDiscountTestElse() {
		RepositoryRequestDTO requestDTOElsedelete=new RepositoryRequestDTO();
		requestDTOElsedelete.setAccnReference("hello");
		 Mockito.when(recordingDiscountRepository.findByRowId(requestDTOElsedelete.getRowId())).thenReturn(null);
		recordingController.deleteRepositoryDiscount(requestDTOElsedelete);
		
	}
	@Test(expected=Exception.class)
	public void downloadCapRepositoryDiscountTestElse() {
		recordingController.downloadCapRepositoryDiscount();
	}
	@Test
	public void downloadCapRepositoryDiscountTestIf() {
		List<RecordingDiscount> recoDownList = new ArrayList<>();
		RecordingDiscount recordingDiscount=new RecordingDiscount();
		recordingDiscount.setAccnReference("123");
		recoDownList.add(recordingDiscount);
		Mockito.when(recordingDiscountRepository.findAllRecordingDiscountByDate()).thenReturn(recoDownList);
		recordingController.downloadCapRepositoryDiscount();
	}
	@Test(expected=Exception.class)
	public void repositoryDiscountAuditListTestElse() {
		recordingController.repositoryDiscountAuditList();
	}
	@Test
	public void repositoryDiscountAuditListTestIf() {
		List<RecordingDiscountAudit> recoAuditList = new ArrayList<>();
		RecordingDiscountAudit recordingDiscountAudit=new RecordingDiscountAudit();
		recordingDiscountAudit.setActionPerformed("Insert");
		recoAuditList.add(recordingDiscountAudit);
		recordingDiscountAudit.setDateTime(new Date("23/03/2024"));
		Mockito.when(recordingDiscountAuditRepository.findAllRecordingDiscountByDate()).thenReturn(recoAuditList);
		recordingController.repositoryDiscountAuditList();
	}
	
	@Test
	public void repositoryDiscountListTest() {
		criteriaBuilderMock = mock(CriteriaBuilder.class);
		criteriaQueryMock = mock(CriteriaQuery.class);
		Mockito.when(entityManager.getCriteriaBuilder()).thenReturn(criteriaBuilderMock);
		Mockito.when(criteriaBuilderMock.createQuery(RecordingDiscount.class))
				.thenReturn((CriteriaQuery<RecordingDiscount>) criteriaQueryMock);

		personRootMock = mock(Root.class);
		RepositoryRequestDTO repositoryRequestDTODis= new RepositoryRequestDTO();
		repositoryRequestDTODis.setRowId(123);
		repositoryRequestDTODis.setUniqueReferenceNo("123");
		repositoryRequestDTODis.setCreatedEin("12345");
		repositoryRequestDTODis.setOcppbReference("ab");
		repositoryRequestDTODis.setAccnReference("gh");
		repositoryRequestDTODis.setProduct("abcde");
		repositoryRequestDTODis.setSubProduct("abc");
		repositoryRequestDTODis.setSpecialOfferCode("1234");
		repositoryRequestDTODis.setSpecialOffBillingDesc("5678");
		repositoryRequestDTODis.setOfferStartDate(new Date("21/1/2023"));
		repositoryRequestDTODis.setOfferEndDate(new Date("21/1/2024"));
		repositoryRequestDTODis.setOfferStartDateStr("21-10-2023");
		repositoryRequestDTODis.setOfferEndDateStr("21/10/2024");
		repositoryRequestDTODis.setChargeType("Rental");
		repositoryRequestDTODis.setBillingFrequency("123");
		repositoryRequestDTODis.setCommercialProposition("yes");
		repositoryRequestDTODis.setProductOwner("no");
		repositoryRequestDTODis.setImpactOffers("ef");
		repositoryRequestDTODis.setNotes("cd");
		repositoryRequestDTODis.setStatus("ab");


		Path product1 = mock(Path.class);
		Expression productUpperExpressionMockElse = mock(Expression.class);
		Predicate lastNameIsLikePredicateMockElse= mock(Predicate.class);

		List<RecordingDiscount> countlistIf = new ArrayList<>();
		RecordingDiscount recordingDiscount = new RecordingDiscount();
		recordingDiscount.setRowId(123);
		recordingDiscount.setCreatedDate(new Date());
		recordingDiscount.setLastUpdateddDate(new Date());
		countlistIf.add(recordingDiscount);

		when(personRootMock.get("uniqueReferenceNo")).thenReturn(product1);
		when(personRootMock.get("ocppbReference")).thenReturn(product1);
		when(personRootMock.get("accnReference")).thenReturn(product1);
		when(personRootMock.get("subProduct")).thenReturn(product1);
		when(personRootMock.get("specialOfferCode")).thenReturn(product1);
		when(personRootMock.get("impactOffers")).thenReturn(product1);
		when(personRootMock.get("offerStartDate")).thenReturn(product1);
		when(personRootMock.get("offerEndDate")).thenReturn(product1);
		when(entityManager.createQuery(criteriaQueryMock)).thenReturn(mockedTypedQuery);

		Mockito.when(mockedTypedQuery.getResultList()).thenReturn(countlistIf);

		Mockito.when(criteriaQueryMock.from(RecordingDiscount.class))
				.thenReturn((Root<RecordingDiscount>) personRootMock);

		when(criteriaBuilderMock.upper(product1)).thenReturn(productUpperExpressionMockElse);
		when(productUpperExpressionMockElse.in(product1)).thenReturn(lastNameIsLikePredicateMockElse);

		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/repositoryDiscountList")
				.param("pageNum", "0").content(asJsonString(repositoryRequestDTODis)).contentType(MediaType.APPLICATION_JSON)
				.accept(MediaType.APPLICATION_JSON);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}
	@Test
	public void repositoryDiscountListTestElse() {
		criteriaBuilderMock = mock(CriteriaBuilder.class);
		criteriaQueryMock = mock(CriteriaQuery.class);
		Mockito.when(entityManager.getCriteriaBuilder()).thenReturn(criteriaBuilderMock);
		Mockito.when(criteriaBuilderMock.createQuery(RecordingDiscount.class))
				.thenReturn((CriteriaQuery<RecordingDiscount>) criteriaQueryMock);

		personRootMock = mock(Root.class);
		RepositoryRequestDTO repositoryRequestDTODisElse= new RepositoryRequestDTO();
		repositoryRequestDTODisElse.setRowId(123);
		Path productElse = mock(Path.class);
		Expression productUpperExpressionMock1 = mock(Expression.class);
		Predicate lastNameIsLikePredicateMock1= mock(Predicate.class);

		List<RecordingDiscount> countlist1 = new ArrayList<>();

	when(personRootMock.get("uniqueReferenceNo")).thenReturn(productElse);
		when(personRootMock.get("ocppbReference")).thenReturn(productElse);
		when(personRootMock.get("accnReference")).thenReturn(productElse);
		when(personRootMock.get("subProduct")).thenReturn(productElse);
		when(personRootMock.get("specialOfferCode")).thenReturn(productElse);
		when(personRootMock.get("impactOffers")).thenReturn(productElse);
		when(personRootMock.get("offerStartDate")).thenReturn(productElse);
		when(personRootMock.get("offerEndDate")).thenReturn(productElse);
		when(entityManager.createQuery(criteriaQueryMock)).thenReturn(mockedTypedQuery);

		Mockito.when(mockedTypedQuery.getResultList()).thenReturn(countlist1);

		Mockito.when(criteriaQueryMock.from(RecordingDiscount.class))
				.thenReturn((Root<RecordingDiscount>) personRootMock);

		when(criteriaBuilderMock.upper(productElse)).thenReturn(productUpperExpressionMock1);
		when(productUpperExpressionMock1.in(productElse)).thenReturn(lastNameIsLikePredicateMock1);

		RequestBuilder requestBuilder1 = MockMvcRequestBuilders.post("/recording/repositoryDiscountList")
				.param("pageNum", "0").content(asJsonString(repositoryRequestDTODisElse)).contentType(MediaType.APPLICATION_JSON)
				.accept(MediaType.APPLICATION_JSON);
		try {
			MvcResult result1 = mockMvc.perform(requestBuilder1).andExpect(status().isOk()).andReturn();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}
}
